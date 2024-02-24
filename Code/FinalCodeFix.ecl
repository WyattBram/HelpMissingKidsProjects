IMPORT $,STD,Visualizer;

HMK := $.File_AllData;


//Declares datasets to variable
MissingChildrenByState := HMK.mc_byStateDS;

HospitalDataSet := HMK.HospitalDS;

FireStationDataSet := HMK.FireDS;

PoliceStationDataSet := HMK.PoliceDS;

PopulationEstimateDataSet := HMK.pop_estimatesDS;



// Makes new tables with data that we want to use


populationn:= TABLE(PopulationEstimateDataSet,{state,attribute,value},state);

CT_City := TABLE(MissingChildrenByState,{missingstate,cnt := COUNT(GROUP)},missingstate);

hospit := TABLE(HospitalDataSet,{state,cnt := COUNT(GROUP)},state);

fireS := TABLE(FireStationDataSet,{state,cnt := COUNT(GROUP)},state);

popos := TABLE(PoliceStationDataSet,{state,cnt := COUNT(GROUP)},state);





EmergencyUnits := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireCount;
// INTEGER popoCount;
// INTEGER hospCount;
END;

FireCombine := JOIN(CT_City, fireS,
LEFT.MissingState = RIGHT.state,
TRANSFORM(EmergencyUnits,
SELF.FireCount := RIGHT.cnt,
SELF.MissingKids := LEFT.cnt,

SELF := LEFT;
SELF := RIGHT));

// OUTPUT(SORT(FireCombine, -MissingKids), NAMED('FireCombine'));

PopoCombine := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireCount;
INTEGER popoCount;
// INTEGER hospCount;
END;

newCase := JOIN(FireCombine, popos,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(PopoCombine,

SELF.FireCount := LEFT.fireCount,
SELF.MissingKids := LEFT.MissingKids,
SELF.popoCount := RIGHT.cnt,

SELF := LEFT;
SELF := RIGHT));

hosp := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireCount;
INTEGER popoCount;
INTEGER hospCount;
END;

ambalance := JOIN(newCase, hospit,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(hosp,

SELF.MissingKids := LEFT.MissingKids,
SELF.popoCount := LEFT.popoCount,
Self.hospCount := RIGHT.cnt,

SELF := LEFT;
SELF := RIGHT));



FinalSheetrec := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireCount;
INTEGER popoCount;
INTEGER hospCount;
INTEGER population;
END;



finalSheet := JOIN(ambalance, populationn,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(FinalSheetrec,

SELF.MissingKids := LEFT.MissingKids,
SELF.popoCount := LEFT.popoCount,
SELF.population := RIGHT.Value;


SELF := LEFT;
SELF := RIGHT));



// OUTPUT(SORT(finalSheet, -MissingKids), NAMED('FinalDataSheet'));


FinalSheetrecPlus := RECORD
// FinalSheet.state;
FinalSheet.MissingKids;
// FinalSheet.FireCount;
// FinalSheet.popoCount;
// FinalSheet.hospCount;
// FinalSheet.population;
// PopPerPolice := FinalSheet.population/FinalSheet.popoCount;
// PopPerhosp := FinalSheet.population/FinalSheet.hospCount;
// PopPerFire := FinalSheet.population/FinalSheet.FireCount;
PopPerTotal := (FinalSheet.population/FinalSheet.popoCount + FinalSheet.population/FinalSheet.hospCount + FinalSheet.population/FinalSheet.FireCount)/3;
END;

NewTable := table(FinalSheet,FinalSheetrecPlus);
OUTPUT(SORT(NewTable, MissingKids),NAMED('thetable'));
Visualizer.MultiD.Line('GraphTitle',,'thetable');

////////////////////////////////////////////////////////////////////////////


FinalSheetrecPlus2 := RECORD
// // FinalSheet.state;
FinalSheet.MissingKids;
// // FinalSheet.FireCount;
// // FinalSheet.popoCount;
// // FinalSheet.hospCount;
// // FinalSheet.population;
//PopPerPolice := FinalSheet.population/FinalSheet.popoCount;
PopPerhosp := FinalSheet.population/FinalSheet.hospCount;
// // PopPerFire := FinalSheet.population/FinalSheet.FireCount;
// // PopPerTotal := (FinalSheet.population/FinalSheet.popoCount + FinalSheet.population/FinalSheet.hospCount + FinalSheet.population/FinalSheet.FireCount)/3;
END;

NewTable2 := table(FinalSheet,FinalSheetrecPlus2);
OUTPUT(SORT(NewTable2, MissingKids),NAMED('thetable2'));
Visualizer.MultiD.Line('GraphTitle2',,'thetable2');

////////////////////////////////////////////////////////////////////////////


FinalSheetrecPlus3 := RECORD
// // FinalSheet.state;
FinalSheet.MissingKids;
// // FinalSheet.FireCount;
// // FinalSheet.popoCount;
// // FinalSheet.hospCount;
// // FinalSheet.population;
// // PopPerPolice := FinalSheet.population/FinalSheet.popoCount;
PopPerhosp := FinalSheet.population/FinalSheet.hospCount;
// // PopPerFire := FinalSheet.population/FinalSheet.FireCount;
// PopPerTotal := (FinalSheet.population/FinalSheet.popoCount + FinalSheet.population/FinalSheet.hospCount + FinalSheet.population/FinalSheet.FireCount)/3;
END;

NewTable3 := table(FinalSheet,FinalSheetrecPlus3);
OUTPUT(SORT(NewTable3, MissingKids),NAMED('thetable3'));
Visualizer.MultiD.Line('GraphTitle3',,'thetable3');


FinalSheetrecPlus4 := RECORD
// // FinalSheet.state;
FinalSheet.MissingKids;
// // FinalSheet.FireCount;
// // FinalSheet.popoCount;
// // FinalSheet.hospCount;
// // FinalSheet.population;
// // PopPerPolice := FinalSheet.population/FinalSheet.popoCount;
// // PopPerhosp := FinalSheet.population/FinalSheet.hospCount;
PopPerFire := FinalSheet.population/FinalSheet.FireCount;
// PopPerTotal := (FinalSheet.population/FinalSheet.popoCount + FinalSheet.population/FinalSheet.hospCount + FinalSheet.population/FinalSheet.FireCount)/3;
END;

NewTable4 := table(FinalSheet,FinalSheetrecPlus4);
OUTPUT(SORT(NewTable4, MissingKids),NAMED('thetable4'));
Visualizer.MultiD.Line('GraphTitle4',,'thetable4');