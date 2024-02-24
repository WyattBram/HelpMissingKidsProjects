IMPORT $,STD,Visualizer;

HMK := $.File_AllData;


//Declares datasets
MissingChildrenByState := HMK.mc_byStateDS;

HospitalDataSet := HMK.HospitalDS;

FireStationDataSet := HMK.FireDS;

PoliceStationDataSet := HMK.PoliceDS;

PopulationEstimateDataSet := HMK.pop_estimatesDS;



// Makes new tables from dataset above with data that we want to use

// State || Census_2020_POP || Population 
ConcisePopulationTable:= TABLE(PopulationEstimateDataSet,
                    {state,attribute,value},state);

// State || MissingChildrenInState
ConciseMissingChildrenTable := TABLE(MissingChildrenByState,
                    {missingstate,cnt := COUNT(GROUP)},missingstate);

// State || HospitalsInState
ConciseHospitalTable := TABLE(HospitalDataSet,
                    {state,cnt := COUNT(GROUP)},state);

// State || FireStationsInState
ConciseFireStationTable := TABLE(FireStationDataSet,
                    {state,cnt := COUNT(GROUP)},state);

// State || PoliceStationsInState
ConcisePoliceStationTable := TABLE(PoliceStationDataSet,
                    {state,cnt := COUNT(GROUP)},state);




// Makes a record to hold values
ChildrenAndFireStation := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireStations;
END;

// Combines MissingChildrenTable with FireStation table
FireStationCombine := JOIN(ConciseMissingChildrenTable, ConciseFireStationTable,
LEFT.MissingState = RIGHT.state,
TRANSFORM(ChildrenAndFireStation,
SELF.FireStations := RIGHT.cnt,
SELF.MissingKids := LEFT.cnt,
SELF := LEFT;
SELF := RIGHT));

// Makes a record to hold values
PreviousAndPolice := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireStations;
INTEGER PoliceStations;
END;

// Combines FireStationCombine with PoliceStation table
PoliceStationCombine := JOIN(FireStationCombine, ConcisePoliceStationTable,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(PreviousAndPolice,
SELF.FireStations := LEFT.FireStations,
SELF.MissingKids := LEFT.MissingKids,
SELF.PoliceStations := RIGHT.cnt,
SELF := LEFT;
SELF := RIGHT));

// Makes a record to hold values
PreviousAndHospital := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireStations;
INTEGER PoliceStations;
INTEGER Hospitals;
END;

// Combines FireStationCombine with PoliceStation table
HospitalCombine := JOIN(PoliceStationCombine, ConciseHospitalTable,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(PreviousAndHospital,
SELF.MissingKids := LEFT.MissingKids,
SELF.PoliceStations := LEFT.PoliceStations,
Self.Hospitals := RIGHT.cnt,
SELF := LEFT;
SELF := RIGHT));



// Record for data of all fields needed to compute our 
CompleteData := RECORD
STRING state;
INTEGER MissingKids;
INTEGER FireStations;
INTEGER PoliceStations;
INTEGER Hospitals;
INTEGER population;
END;


// Combines Previous with PopulationTable
finalSheet := JOIN(HospitalCombine, ConcisePopulationTable,
STD.Str.ToUpperCase(LEFT.state) = STD.Str.ToUpperCase(RIGHT.state),
TRANSFORM(CompleteData,
SELF.MissingKids := LEFT.MissingKids,
SELF.PoliceStations := LEFT.PoliceStations,
SELF.population := RIGHT.Value;
SELF := LEFT;
SELF := RIGHT));

OUTPUT(SORT(finalSheet, -MissingKids),NAMED('tempTable'));

////////////////////////////////////////////////////////////////////////////

//Makes record of State || MissingKids || AveragePeoplePerEmergencyService
PeoplePerEmergencyService := RECORD
FinalSheet.MissingKids;
PopPerTotal := (FinalSheet.population/FinalSheet.PoliceStations + 
FinalSheet.population/FinalSheet.Hospitals + FinalSheet.population/FinalSheet.FireStations)/3;
END;

//Outputs the table for our calculation of Population/TotalEMS and visualizes it
EMSTable := table(FinalSheet,PeoplePerEmergencyService);
OUTPUT(SORT(EMSTable, MissingKids),NAMED('EMSTable'));
Visualizer.MultiD.Line('EMSGraph',,'EMSTable');

////////////////////////////////////////////////////////////////////////////

//Makes record of State || MissingKids || AveragePeoplePerPoliceStation
PeoplePerPoliceStation := RECORD
FinalSheet.MissingKids;
PopPerhosp := FinalSheet.population/FinalSheet.PoliceStations;
END;

//Outputs the table for our calculation of Population/PoliceStation and visualizes it
PoliceStationTable := table(FinalSheet,PeoplePerPoliceStation);
OUTPUT(SORT(PoliceStationTable, MissingKids),NAMED('PoliceStationTable'));
Visualizer.MultiD.Line('PoliceStationGraph',,'PoliceStationTable');

////////////////////////////////////////////////////////////////////////////

//Makes record of State || MissingKids || AveragePeoplePerHospital
PeoplePerHospital := RECORD
FinalSheet.MissingKids;
PopPerhosp := FinalSheet.population/FinalSheet.Hospitals;
END;

//Outputs the table for our calculation of Population/Hospitals and visualizes it
HospitalTable := table(FinalSheet,PeoplePerHospital);
OUTPUT(SORT(HospitalTable, MissingKids),NAMED('HospitalTable'));
Visualizer.MultiD.Line('HospitalGraph',,'HospitalTable');

////////////////////////////////////////////////////////////////////////////

//Makes record of State || MissingKids || AveragePeoplePerFireStation
PeoplePerFireStation := RECORD
FinalSheet.MissingKids;
PopPerFire := FinalSheet.population/FinalSheet.FireStations;
END;

//Outputs the table for our calculation of Population/FireStations and visualizes it
FireStationTable := table(FinalSheet,PeoplePerFireStation);
OUTPUT(SORT(FireStationTable, MissingKids),NAMED('FireStationTable'));
Visualizer.MultiD.Line('FireStationGraph',,'FireStationTable');
