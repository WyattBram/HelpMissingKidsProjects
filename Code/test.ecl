IMPORT =STD,Visualizer,$;
HMK := $.File_AllData;

NCMEC_Rec := HMK.mc_byState;
NCMEC_DS  := HMK.File_AllData.mc_byStateDS;
Cities    := HMK.File_AllData.City_DS;
UNEMP     := HMK.File_AllData.unemp_byCountyDS;
EDU       := HMK.File_AllData.EducationDS;
POVTY     := HMK.File_AllData.pov_estimatesDS;
POP       := HMK.File_AllData.pop_estimatesDS;

// OUTPUT(NCMEC_DS);
// Sequence Records
// Standardizing Dates
// Name and Contact Standardization
// Add PrimaryFIPS Field to Dataset
// Cross Tab Reports, By City, State, Date Missing, FIPS
NewNCMECLayout := $.File_EnhanceNCMEC.NCMECPlusLayout;

NewNCMECLayout CleanNCMEC(NCMEC_DS Le,UNSIGNED2 CNT) := TRANSFORM
 // SELF.RecID    := CNT; //Now uses Case Number
 SELF.DatePosted  := STD.Date.FromStringToDate(Le.DatePosted,'%m/%d/%Y');
 SELF.FirstName   := STD.Str.ToUpperCase(Le.FirstName);
 SELF.LastName    := STD.Str.ToUpperCase(Le.LastName);
 // SELF.DateMissing := STD.Date.FromStringToDate(Le.DateMissing,'%m/%d/%Y'); //Processed earlier
 SELF.MissingCity := STD.Str.ToUpperCase(Le.MissingCity);
 SELF.Contact     := STD.Str.ToUpperCase(Le.Contact);
 SELF.PrimaryFIPS := 0; 
 SELF.ump_rate    := 0;
 SELF.pov_pct     := 0;
 SELF.PopEst      := 0;
 SELF.edu_High    := 0;
 SELF             := Le;
 END;
//Step 1: Make room for new metrics, standardize dates, names, contact and sequence records
Clean_NCMEC_DS := PROJECT(NCMEC_DS,CleanNCMEC(LEFT,COUNTER));
OUTClean_NCMEC_DS := OUTPUT(Clean_NCMEC_DS,NAMED('DataCleaned'));

NewNCMECLayout GetFIPS(Clean_NCMEC_DS Le,Cities Ri) := TRANSFORM
SELF.PrimaryFIPS := (UNSIGNED3)Ri.county_fips;
SELF             := Le; 
END;

AddFIPS := JOIN(Clean_NCMEC_DS,Cities,
                LEFT.missingcity = STD.STR.ToUpperCase(RIGHT.city) AND
                LEFT.missingstate = RIGHT.state_id,
                GetFIPS(LEFT,RIGHT),LEFT OUTER);
Out_addFips := OUTPUT(AddFips,NAMED('FIPSAdded'));

// OUTPUT(AddFips(PrimaryFIPS = 6025));


//Cross-Tab by City: 

CT_City := TABLE(AddFIPS,{missingcity,missingstate,cnt := COUNT(GROUP)},missingstate,missingcity);
Out_CT_City := OUTPUT(SORT(CT_City,-cnt),NAMED('MissByCity'));

//Cross-Tab by State:

CT_ST := TABLE(AddFIPS,{missingstate,cnt := COUNT(GROUP)},missingstate);
Out_CT_ST := OUTPUT(SORT(CT_ST,-cnt),NAMED('MissByState'));

//Cross-Tab by Date Missing:

CT_date := TABLE(AddFIPS,{DateMissing,cnt := COUNT(GROUP)},DateMissing);
Out_CTdate := OUTPUT(SORT(CT_date,-cnt),NAMED('MissByDate'));

//Cross-Tab by Primary FIPS:

CT_FIPS := TABLE(AddFIPS,{PrimaryFIPS,cnt := COUNT(GROUP)},PrimaryFIPS);
Out_CT_FIPS := OUTPUT(SORT(CT_FIPS,-cnt),NAMED('MissByFIPS'));

//Visualizer example:
Visualizer.Choropleth.USStates('MissingByState', , 'MissByState', , , DATASET([{'paletteID', 'PuBuGn'}], Visualizer.KeyValueDef));

//Add Unemployment Rate for area:
CT_UNEMP := TABLE(UNEMP((STD.Str.Find(attribute, 'Unemployment_rate',1) <> 0)),
                {Fips_Code,cnt := ROUND(AVE(GROUP,value),2)},Fips_Code);
// OUTPUT(SORT(CT_UNEMP,-cnt),NAMED('UNEMP_Rate'));

ADDUMP := JOIN(AddFIPS,CT_UNEMP,LEFT.PrimaryFIPS=RIGHT.Fips_Code,
               TRANSFORM(NewNCMECLayout,
                         SELF.ump_rate := RIGHT.cnt,
                         SELF := LEFT),LEFT OUTER,LOOKUP);
                         
// OUTPUT(ADDUMP,NAMED('AddUMPRate')); 

//Add Poverty Percentage ages 0-17 for FIPS area:
POVTBL := TABLE(POVTY((STD.Str.Find(attribute, 'PCTPOV017_2021',1) <> 0)),
                {Fips_Code,attribute,value});
// OUTPUT(SORT(POVTBL,-value),NAMED('PovertyPct0to17'));

ADDPOV := JOIN(AddUMP,POVTBL,LEFT.PrimaryFIPS=RIGHT.Fips_Code,
               TRANSFORM(NewNCMECLayout,
                         SELF.pov_pct := RIGHT.value,
                         SELF := LEFT),LEFT OUTER,LOOKUP);
                         
// OUTPUT(ADDPOV,NAMED('AddPOVRate'));

//Add Average population for 2020-2022 by FIPS (FIPS=0 defaults to national average) 
POPCT_FIPS := TABLE(POP((STD.Str.Find(attribute, 'POP_ESTIMATE',1) <> 0)),
                 {Fips_Code,tot := ROUND(AVE(GROUP,value))},fips_code); 
                 
// OUTPUT(SORT(POPCT_FIPS,-tot),NAMED('PopByFIPS'));

ADDPOP := JOIN(AddPOV,POPCT_FIPS,LEFT.PrimaryFIPS=RIGHT.Fips_Code,
               TRANSFORM(NewNCMECLayout,
                         SELF.PopEst := RIGHT.tot,
                         SELF := LEFT),LEFT OUTER,LOOKUP);
                         
// OUTPUT(ADDPOP,NAMED('AddPOPEst'));

//Percent of adults with less than a high school diploma, 1970               


EDU_CT_FIPS := TABLE(EDU((STD.Str.Find(attribute, 'Percent of adults with less than a high school diploma',1) <> 0)),
                {Fips_Code,tot := ROUND(AVE(GROUP,value),2)},fips_code);
// OUTPUT(SORT(EDU_CT_FIPS,-tot),NAMED('NoHighSch'));
// OUTPUT(EDU(Fips_Code=2160)); //County with highest illiteracy
ADDEDU := JOIN(AddPOP,EDU_CT_FIPS,LEFT.PrimaryFIPS=RIGHT.Fips_Code,
               TRANSFORM(NewNCMECLayout,
                         SELF.edu_High := RIGHT.tot,
                         SELF := LEFT),LEFT OUTER,LOOKUP);

//Write to a file so we can INDEX for ROXIE                         
Write_File := OUTPUT(ADDEDU,,'~HMK::OUT::NECMCPlus',NAMED('FinalOut'),OVERWRITE);

SEQUENTIAL(OUTClean_NCMEC_DS,
           Out_addFips,
           PARALLEL(Out_CT_City,Out_CT_ST,Out_CTdate,Out_CT_FIPS),
           Write_File);