insert into appuser (
    id,
    username,
    password,
    email,
    title,
    firstname,
    lastname,
    organisation,
    dataspaceagentdescription,
    dataspaceagenturi,
    dataspaceagentupdatedate,
    admin,
	aafid,
	passwordresettoken,
	passwordresetexpiresat,
	createdate
)
select
    case when ((select count(*) from appuser) > 0) then (select max(id) from appuser) else 1 end,
    'admin',
    '$2a$10$xXuqK0St8Hu4betgocquQO/zfIgah.6u1e1/cbPFCve8K.s.EPze.',
    'admin@example.org',
    NULL,
    'System',
    'Administrator',
    'OzTrack',
    NULL,
    NULL,
    NULL,
    true,
    NULL,
    NULL,
    NULL,
    localtimestamp
where not exists (select * from appuser where admin);