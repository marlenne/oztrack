alter table positionfix
    drop column sensor1units,
    drop column sensor1value,
    drop column sensor2units,
    drop column sensor2value,
    drop column hdop;
alter table rawpositionfix
    drop column sensor1units,
    drop column sensor1value,
    drop column sensor2units,
    drop column sensor2value,
    drop column hdop;
alter table animal drop column sensortransmitterid;
drop table rawacousticdetection;
drop table acousticdetection;
drop sequence acousticdetectionid_seq;
drop table receiverdeployment;
drop sequence receiverdeployid_seq;
drop table receiverlocation;
drop sequence receiverlocatid_seq;