declare @currentDateTime varchar(25);

drop table if exists #tmpDataAreaIds;

create table #tmpDataAreaIds (
	Id int identity(1,1) not null,
	DataAreaId nvarchar(4) not null
);

-- Replace these with the company/companies that you have
insert into #tmpDataAreaIds (DataAreaId) values
('USMF'),
('USPM');

-- Phone (1), Telex (4) and Fax (5) in LOGISTICSELECTRONICADDRESS
----------------------------------------------------------------------------------
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning phone and fax in LOGISTICSELECTRONICADDRESS...', 10, 1, @currentDateTime) with nowait;

-- Used a fake US phone number, change if necessary
update dbo.LOGISTICSELECTRONICADDRESS
set LOCATOR = N'202-555-0103'
where [PARTITION] = 5637144576
and [TYPE] in (1,4,5)
and LOCATOR is NOT NULL
and LOCATOR <> N'202-555-0103';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned phone and fax in LOGISTICSELECTRONICADDRESS.', 10, 1, @currentDateTime) with nowait;

-- email (2) in LOGISTICSELECTRONICADDRESS
----------------------------------------------------------------------------------
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning emails in LOGISTICSELECTRONICADDRESS...', 10, 1, @currentDateTime) with nowait;

update dbo.LOGISTICSELECTRONICADDRESS
set LOCATOR = N'website@info.com'
WHERE [PARTITION] = 5637144576
and [TYPE] = 2
and LOCATOR is NOT NULL
and LOCATOR <> N'website@info.com'; 

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned emails in LOGISTICSELECTRONICADDRESS.', 10, 1, @currentDateTime) with nowait;

-- url (3) in LOGISTICSELECTRONICADDRESS
----------------------------------------------------------------------------------
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning URLs in LOGISTICSELECTRONICADDRESS...', 10, 1, @currentDateTime) with nowait;

update dbo.LOGISTICSELECTRONICADDRESS
set LOCATOR = N'http://127.0.0.1/'
WHERE [PARTITION] = 5637144576
and [TYPE] = 3
and LOCATOR is NOT NULL
and LOCATOR <> N'http://127.0.0.1/';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned URLs in LOGISTICSELECTRONICADDRESS.', 10, 1, @currentDateTime) with nowait;

-- VAT Numbers that still contain the actual VAT in CUSTTABLE
----------------------------------------------------------------------------------

drop table if exists #tmpVatNums;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Filling new VATNUM into temporary table...', 10, 1, @currentDateTime) with nowait;

select	N'VatNum ' + RIGHT('0000000'+CAST((ROW_NUMBER() OVER( ORDER BY c.RECID )) as nvarchar(7)),7) as NewVatNumName,
		RIGHT('0000000'+CAST((ROW_NUMBER() OVER( ORDER BY c.RECID )) as nvarchar(7)),7) as NewVatNum,
		c.RECID as CustTableRecId,
		tvn.RECID as TaxVatNumTableRecId
into #tmpVatNums
from dbo.CUSTTABLE as c
inner join dbo.TAXVATNUMTABLE as tvn --47538
	on tvn.[PARTITION] = c.[PARTITION]
	and tvn.DATAAREAID = c.DATAAREAID
	and tvn.VATNUM = c.VATNUM

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning VAT Numbers in CUSTTABLE...', 10, 1, @currentDateTime) with nowait;

update c
set c.VATNUM = vn.NewVatNum
from dbo.CUSTTABLE as c
inner join #tmpVatNums as vn
	on vn.CustTableRecId = c.RECID;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning VATNUM and NAME in dbo.TAXVATNUMTABLE...', 10, 1, @currentDateTime) with nowait;

update tvn
set tvn.VATNUM = vn.NewVatNum,
	tvn.[NAME] = vn.NewVatNumName
from dbo.TAXVATNUMTABLE as tvn
inner join #tmpVatNums as vn
	on vn.TaxVatNumTableRecId = tvn.RECID;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning leftovers in dbo.TAXVATNUMTABLE...', 10, 1, @currentDateTime) with nowait;

-- delete leftovers that have no link with custtable
delete
from dbo.TAXVATNUMTABLE
where not exists (
	select 1
	from #tmpVatNums
	where TaxVatNumTableRecId = RECID
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning Fiscal codes in CUSTTABLE...', 10, 1, @currentDateTime) with nowait;

UPDATE dbo.CUSTTABLE
SET FISCALCODE = N''
WHERE [PARTITION] = 5637144576
and DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
)
and FISCALCODE <> N'';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned Fiscal codes in CUSTTABLE.', 10, 1, @currentDateTime) with nowait;

-- Update names of customers in DIRPARTYTABLE
----------------------------------------------------------------------------------
declare @incNum int = 0,
		@max bigint,
		@min bigint;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning IMPORTVATNUM in dbo.DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

set @min = 1;
set @max = 99999999999;

update dbo.DIRPARTYTABLE
set IMPORTVATNUM = right(replicate('0', LEN(@max)) + convert(varchar, ABS(CHECKSUM(NEWID()) % (@max - @min - 1)) + @min), len(@max))
where IMPORTVATNUM is not null
and IMPORTVATNUM <> N'';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning ORGNUMBER in dbo.DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

set @min = 1;
set @max = 9999999999;

update p
set p.ORGNUMBER = right(replicate('0', LEN(@max)) + convert(varchar, ABS(CHECKSUM(NEWID()) % (@max - @min - 1)) + @min), len(@max))
from dbo.DIRPARTYTABLE as p
where p.ORGNUMBER <> N''
and p.ORGNUMBER is not null;

set @min = 1;
set @max = 99999999999;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning VATNUM in dbo.DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

update dbo.DIRPARTYTABLE
set VATNUM = right(replicate('0', LEN(@max)) + convert(varchar, ABS(CHECKSUM(NEWID()) % (@max - @min - 1)) + @min), len(@max))
where VATNUM is not null
and VATNUM <> N'';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Filling temporary table with new person name for DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

drop table if exists #tmpDirPartyPersons;

-- Fill a temporary table so we can update 2 tables with the RecId for persons
select	p.RECID as DirPartyTableRecId,
		N'Person ' + RIGHT('0000000'+CAST((ROW_NUMBER() OVER( ORDER BY p.RECID )) as nvarchar(7)),7) as NewPersonName
into #tmpDirPartyPersons
from dbo.DIRPARTYTABLE as p
inner join dbo.DIRPERSONNAME as pn
	on pn.[PARTITION] = p.[PARTITION]
	and pn.PERSON = p.RECID
where p.[PARTITION] = 5637144576
and p.INSTANCERELATIONTYPE in (12261, 3276, 5441)

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME and NAMEALIAS for persons in dbo.DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

update p
set p.[NAME] = tp.NewPersonName,
	p.NAMEALIAS = LEFT(tp.NewPersonName, 20)
from dbo.DIRPARTYTABLE as p
inner join #tmpDirPartyPersons as tp
	on tp.DirPartyTableRecId = p.RECID;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning FIRSTNAME and LASTNAME in dbo.DIRPERSONNAME...', 10, 1, @currentDateTime) with nowait;

update personNames
set personNames.FIRSTNAME = tp.NewPersonName,
	personNames.LASTNAME = tp.NewPersonName
from dbo.DIRPERSONNAME as personNames
inner join #tmpDirPartyPersons as tp
	on tp.DirPartyTableRecId = personNames.PERSON;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME for persons in dbo.CUSTCOLLECTIONLETTERJOUR...', 10, 1, @currentDateTime) with nowait;
	
update cclj
set cclj.[NAME] = dpp.NewPersonName
from dbo.CUSTCOLLECTIONLETTERJOUR as cclj
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cclj.[PARTITION]
	and ct.DATAAREAID = cclj.DATAAREAID
	and ct.ACCOUNTNUM = cclj.ACCOUNTNUM
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyPersons as dpp
	on dpp.DirPartyTableRecId = dpt.RECID
where cclj.[PARTITION] = 5637144576
and cclj.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
)
and cclj.[NAME] not like N'Person %';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Creating temporary table for persons for CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;
	
drop table if exists #tmpCustInvoiceJourUpdatedPersons;

-- Normally the CREATE statement is not required with an INTO statement, but output + into does require one.
-- Table is used to easily update CustInvoiceTrans with less joins, used FinOps 'CustInvoiceJour' relation's fields
create table #tmpCustInvoiceJourUpdatedPersons (
	CustInvoiceJourRecId bigint not null, -- for easy lookup
	NewDeliveryName nvarchar(100) not null,
	[Partition] bigint not null,
	DataAreaId nvarchar(4) not null,
	SalesId nvarchar(20) not null,
	InvoiceID nvarchar(20) not null,
	InvoiceDate datetime not null,
	NumberSequenceGroup nvarchar(10) not null
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning DELIVERYNAME and INVOICINGNAME for persons in dbo.CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;

update cij
set cij.DELIVERYNAME = dpp.NewPersonName,
	cij.INVOICINGNAME = dpp.NewPersonName
output inserted.RECID, inserted.DELIVERYNAME, inserted.[PARTITION], inserted.DATAAREAID, 
		inserted.SALESID, inserted.INVOICEID, inserted.INVOICEDATE, inserted.NUMBERSEQUENCEGROUP
into #tmpCustInvoiceJourUpdatedPersons
from dbo.CUSTINVOICEJOUR as cij
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cij.[PARTITION]
	and ct.DATAAREAID = cij.DATAAREAID
	and ct.ACCOUNTNUM = cij.ORDERACCOUNT
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyPersons as dpp
	on dpp.DirPartyTableRecId = dpt.RECID
where cij.[PARTITION] = 5637144576
and cij.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning MCRDELIVERYNAME for persons in dbo.CUSTINVOICETRANS...', 10, 1, @currentDateTime) with nowait;

update cit
set cit.MCRDELIVERYNAME = tcijup.NewDeliveryName
from dbo.CUSTINVOICETRANS as cit
inner join #tmpCustInvoiceJourUpdatedPersons as tcijup
	on tcijup.[PARTITION] = cit.[PARTITION]
	and tcijup.DATAAREAID = cit.DATAAREAID
	and tcijup.SALESID = cit.SALESID
	and tcijup.INVOICEID = cit.INVOICEID
	and tcijup.INVOICEDATE = cit.INVOICEDATE
	and tcijup.NUMBERSEQUENCEGROUP = cit.NUMBERSEQUENCEGROUP
where cit.[PARTITION] = 5637144576
and cit.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Filling temporary table with new organization name for DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

drop table if exists #tmpDirPartyOrganizations;

-- Fill a temporary table so we can update 2 tables with the RecId for organizations
select  p.RECID as DirPartyTableRecId,
		N'Organization ' + RIGHT('0000000'+CAST((ROW_NUMBER() OVER( ORDER BY p.RECID )) as nvarchar(7)),7) as NewOrganizationName
into #tmpDirPartyOrganizations
from dbo.DIRPARTYTABLE as p
inner join dbo.DIRORGANIZATIONNAME as o
	on o.[PARTITION] = p.[PARTITION]
	and o.ORGANIZATION = p.RECID
where p.[PARTITION] = 5637144576
and p.INSTANCERELATIONTYPE in (12261, 3276, 5441)

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME and NAMEALIAS for organizations in dbo.DIRPARTABLE...', 10, 1, @currentDateTime) with nowait;

update p
set p.[NAME] = tpo.NewOrganizationName,
	p.NAMEALIAS = left(tpo.NewOrganizationName, 20)
from dbo.DIRPARTYTABLE as p
inner join #tmpDirPartyOrganizations as tpo
	on p.RECID = tpo.DirPartyTableRecId

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME in dbo.DIRORGANIZATIONNAME...', 10, 1, @currentDateTime) with nowait;

update orgs
set orgs.[NAME] = tpo.NewOrganizationName
from dbo.DIRORGANIZATIONNAME as orgs
inner join #tmpDirPartyOrganizations as tpo
	on tpo.DirPartyTableRecId = orgs.ORGANIZATION;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME for organizations in dbo.CUSTCOLLECTIONLETTERJOUR...', 10, 1, @currentDateTime) with nowait;
	
update cclj
set cclj.[NAME] = dpo.NewOrganizationName
from dbo.CUSTCOLLECTIONLETTERJOUR as cclj
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cclj.[PARTITION]
	and ct.DATAAREAID = cclj.DATAAREAID
	and ct.ACCOUNTNUM = cclj.ACCOUNTNUM
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyOrganizations as dpo
	on dpo.DirPartyTableRecId = dpt.RECID
where cclj.[PARTITION] = 5637144576
and cclj.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
)
and cclj.[NAME] not like N'Organization %';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Creating temporary table for organizations for CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;
	
drop table if exists #tmpCustInvoiceJourUpdatedOrganizations;

-- Normally the CREATE statement is not required with an INTO statement, but output + into does require one.
-- Table is used to easily update CustInvoiceTrans with less joins, used FinOps 'CustInvoiceJour' relation's fields
create table #tmpCustInvoiceJourUpdatedOrganizations (
	CustInvoiceJourRecId bigint not null, -- for easy lookup
	NewDeliveryName nvarchar(100) not null,
	[Partition] bigint not null,
	DataAreaId nvarchar(4) not null,
	SalesId nvarchar(20) not null,
	InvoiceID nvarchar(20) not null,
	InvoiceDate datetime not null,
	NumberSequenceGroup nvarchar(10) not null
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning DELIVERYNAME and INVOICINGNAME for organizations in dbo.CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;
	
update cij
set cij.DELIVERYNAME = dpo.NewOrganizationName,
	cij.INVOICINGNAME = dpo.NewOrganizationName
output inserted.RECID, inserted.DELIVERYNAME, inserted.[PARTITION], inserted.DATAAREAID, 
		inserted.SALESID, inserted.INVOICEID, inserted.INVOICEDATE, inserted.NUMBERSEQUENCEGROUP
into #tmpCustInvoiceJourUpdatedOrganizations
from dbo.CUSTINVOICEJOUR as cij
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cij.[PARTITION]
	and ct.DATAAREAID = cij.DATAAREAID
	and ct.ACCOUNTNUM = cij.ORDERACCOUNT
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyOrganizations as dpo
	on dpo.DirPartyTableRecId = dpt.RECID
where cij.[PARTITION] = 5637144576
and cij.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning MCRDELIVERYNAME for organizations in dbo.CUSTINVOICETRANS...', 10, 1, @currentDateTime) with nowait;

update cit
set cit.MCRDELIVERYNAME = tcijuo.NewDeliveryName
from dbo.CUSTINVOICETRANS as cit
inner join #tmpCustInvoiceJourUpdatedOrganizations as tcijuo
	on tcijuo.[PARTITION] = cit.[PARTITION]
	and tcijuo.DATAAREAID = cit.DATAAREAID
	and tcijuo.SALESID = cit.SALESID
	and tcijuo.INVOICEID = cit.INVOICEID
	and tcijuo.INVOICEDATE = cit.INVOICEDATE
	and tcijuo.NUMBERSEQUENCEGROUP = cit.NUMBERSEQUENCEGROUP
where cit.[PARTITION] = 5637144576
and cit.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

-- The following are leftovers that do not seem to link to either Organizations or Persons.
-- Might need to be investigated to which these link, they are customers

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Filling temporary table with new party name for DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

drop table if exists #tmpDirPartyParties;

-- Fill a temporary table so we can update 2 tables with the RecId for organizations
select	p.recid as DirPartyTableRecId,
		N'Party ' + RIGHT('0000000'+CAST((ROW_NUMBER() OVER( ORDER BY p.RECID )) as nvarchar(7)),7) as NewPartyName
into #tmpDirPartyParties
from dbo.DIRPARTYTABLE as p
inner join dbo.CUSTTABLE as c
	on c.[PARTITION] = p.[PARTITION]
	and c.PARTY = p.RECID
where name not like N'Person%'
and name not like N'Orga%'

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME and NAMEALIAS for parties in dbo.DIRPARTABLE...', 10, 1, @currentDateTime) with nowait;

update p
set p.[NAME] = tdpp.NewPartyName,
	p.NAMEALIAS = left(tdpp.NewPartyName, 20)
from dbo.DIRPARTYTABLE as p
inner join #tmpDirPartyParties as tdpp
	on p.RECID = tdpp.DirPartyTableRecId;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning NAME for parties in dbo.CUSTCOLLECTIONLETTERJOUR...', 10, 1, @currentDateTime) with nowait;
	
update cclj
set cclj.[NAME] = dppt.NewPartyName
from dbo.CUSTCOLLECTIONLETTERJOUR as cclj
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cclj.[PARTITION]
	and ct.DATAAREAID = cclj.DATAAREAID
	and ct.ACCOUNTNUM = cclj.ACCOUNTNUM
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyParties as dppt
	on dppt.DirPartyTableRecId = dpt.RECID
where cclj.[PARTITION] = 5637144576
and cclj.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
)
and cclj.[NAME] not like N'Party %';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Creating temporary table for parties for CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;
	
drop table if exists #tmpCustInvoiceJourUpdatedParties;

-- Normally the CREATE statement is not required with an INTO statement, but output + into does require one.
-- Table is used to easily update CustInvoiceTrans with less joins, used FinOps 'CustInvoiceJour' relation's fields
create table #tmpCustInvoiceJourUpdatedParties (
	CustInvoiceJourRecId bigint not null, -- for easy lookup
	NewDeliveryName nvarchar(100) not null,
	[Partition] bigint not null,
	DataAreaId nvarchar(4) not null,
	SalesId nvarchar(20) not null,
	InvoiceID nvarchar(20) not null,
	InvoiceDate datetime not null,
	NumberSequenceGroup nvarchar(10) not null
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning DELIVERYNAME and INVOICINGNAME for parties in dbo.CUSTINVOICEJOUR...', 10, 1, @currentDateTime) with nowait;
	
update cij
set cij.DELIVERYNAME = dppt.NewPartyName,
	cij.INVOICINGNAME = dppt.NewPartyName
from dbo.CUSTINVOICEJOUR as cij
inner join dbo.CUSTTABLE as ct
	on ct.[PARTITION] = cij.[PARTITION]
	and ct.DATAAREAID = cij.DATAAREAID
	and ct.ACCOUNTNUM = cij.ORDERACCOUNT
inner join dbo.DIRPARTYTABLE as dpt
	on dpt.[PARTITION] = ct.[PARTITION]
	and dpt.RECID = ct.PARTY
inner join #tmpDirPartyParties as dppt
	on dppt.DirPartyTableRecId = dpt.RECID
where cij.[PARTITION] = 5637144576
and cij.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning MCRDELIVERYNAME for parties in dbo.CUSTINVOICETRANS...', 10, 1, @currentDateTime) with nowait;

update cit
set cit.MCRDELIVERYNAME = tcijup.NewDeliveryName
from dbo.CUSTINVOICETRANS as cit
inner join #tmpCustInvoiceJourUpdatedParties as tcijup
	on tcijup.[PARTITION] = cit.[PARTITION]
	and tcijup.DATAAREAID = cit.DATAAREAID
	and tcijup.SALESID = cit.SALESID
	and tcijup.INVOICEID = cit.INVOICEID
	and tcijup.INVOICEDATE = cit.INVOICEDATE
	and tcijup.NUMBERSEQUENCEGROUP = cit.NUMBERSEQUENCEGROUP
where cit.[PARTITION] = 5637144576
and cit.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning filled birthdates in dbo.DIRPARTYTABLE...', 10, 1, @currentDateTime) with nowait;

update p
set p.BIRTHDAY = 1,
	p.BIRTHMONTH = 1,
	p.BIRTHYEAR = 1990
from dbo.DIRPARTYTABLE as p 
where p.[PARTITION] = 5637144576
and p.BIRTHDAY is not null
and p.BIRTHMONTH is not null
and p.BIRTHYEAR is not null
and (p.BIRTHDAY <> 0 and p.BIRTHMONTH <> 0 and p.BIRTHYEAR <> 0);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning LEDGERDIMENSIONNAME in dbo.LEDGERJOURNALTRANS...', 10, 1, @currentDateTime) with nowait;

set @incNum = 0;

-- TODO: Check whether this cleaning is meaningful.
--		 If this is linked to the customer in some way, it is better to have the same name as it was changed on DirPartyTable.
update dbo.LEDGERJOURNALTRANS
set @incNum = @incNum + 1,
	LEDGERDIMENSIONNAME = N'DIM ' + RIGHT('000000000000'+CAST(@incNum as nvarchar(12)),12)
where LEDGERDIMENSIONNAME <> N'';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning PERSONNELNUMBER in dbo.HCMWORKER...', 10, 1, @currentDateTime) with nowait;

set @incNum = 0;

update dbo.HCMWORKER
set @incNum = @incNum + 1,
	PERSONNELNUMBER = N'PSNR ' + RIGHT('000000000000'+CAST(@incNum as nvarchar(12)),12)
where PERSONNELNUMBER <> N'';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning dbo.DOCUREF, dbo.DOCUVALUE...', 10, 1, @currentDateTime) with nowait;

truncate table DOCUREF
truncate table DOCUVALUE

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning IBAN and DEBITDIRECTID in dbo.BANKACCOUNTTABLE...', 10, 1, @currentDateTime) with nowait;

set @incNum = 0;

-- Took a random Belgium IBAN which is not valid except from it being 16 long
update ba
set @incNum = @incNum + 1,
	ba.IBAN = N'BE68539' + RIGHT('000000000'+CAST(@incNum as nvarchar(9)),9),
	ba.DEBITDIRECTID = right(N'BE68539' + RIGHT('000000000'+CAST(@incNum as nvarchar(9)),9), 5)
from dbo.BANKACCOUNTTABLE as ba

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning STREET and STREETNUMBER in dbo.LOGISTICSPOSTALADDRESS...', 10, 1, @currentDateTime) with nowait;

set @min = 1;
set @max = 999;

update lpa
set lpa.[address] = FORMATMESSAGE(N'%s %s %s %s %s %s %s', 
								  lpa.POSTBOX, 
								  N'Dynamics Avenue', 
								  convert(varchar, ABS(CHECKSUM(NEWID()) % (@max - @min - 1)) + @min),
								  lpa.ZIPCODE,
								  lpa.CITY,
								  lpa.COUNTY,
								  lpa.COUNTRYREGIONID),
	lpa.STREET = N'Dynamics Avenue',
	lpa.STREETNUMBER = convert(varchar, ABS(CHECKSUM(NEWID()) % (@max - @min - 1)) + @min)
from dbo.LOGISTICSPOSTALADDRESS as lpa
where lpa.[PARTITION] = 5637144576;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning DESCRIPTION in dbo.LOGISTICSLOCATION...', 10, 1, @currentDateTime) with nowait;

update dbo.LOGISTICSLOCATION
set [DESCRIPTION] = N'A location''s description'
where [PARTITION] = 5637144576
and [DESCRIPTION] <> N''
and [DESCRIPTION] <> N'Delivery';

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned Customer names in DIRPARTYTABLE.', 10, 1, @currentDateTime) with nowait;

-- Update bank data for a specific customer in CUSTBANKACCOUNT
----------------------------------------------------------------------------------
set @incNum = 0;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning Bank IBAN in CUSTBANKACCOUNT...', 10, 1, @currentDateTime) with nowait;

-- Took a random Belgium IBAN which is not valid except from it being 16 long
update b
set @incNum = @incNum + 1,
	b.[NAME] = N'BE68539' + RIGHT('000000000'+CAST(@incNum as nvarchar(9)),9),
	b.BANKIBAN = N'BE68539' + RIGHT('000000000'+CAST(@incNum as nvarchar(9)),9),
	b.CONTACTPERSON = N'Person ' + RIGHT('0000000'+CAST(@incNum as nvarchar(7)),7)
from dbo.CUSTBANKACCOUNT as b
inner join dbo.CUSTTABLE as c
	on c.[PARTITION] = b.[PARTITION]
	and c.DATAAREAID = b.DATAAREAID
	and c.ACCOUNTNUM = b.CUSTACCOUNT
where b.[PARTITION] = 5637144576
and b.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned Bank IBAN in CUSTBANKACCOUNT.', 10, 1, @currentDateTime) with nowait;

-- Update name in CUSTINVOICETABLE
----------------------------------------------------------------------------------
set @incNum = 0;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning name in CUSTINVOICETABLE...', 10, 1, @currentDateTime) with nowait;

update i
set @incNum = @incNum + 1,
	i.[NAME] = N'Person ' + RIGHT('0000000'+CAST(@incNum as nvarchar(7)),7)
from dbo.CUSTINVOICETABLE as i
where i.[PARTITION] = 5637144576
and i.DATAAREAID in (
    select DataAreaId
    from #tmpDataAreaIds
);

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaned name in CUSTINVOICETABLE.', 10, 1, @currentDateTime) with nowait;

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning SYSDATABASELOG...', 10, 1, @currentDateTime) with nowait;

-- Empty database logging
truncate table dbo.SYSDATABASELOG;

-- Empty batch configuration that is related to the orig
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning Server config...', 10, 1, @currentDateTime) with nowait;

truncate table dbo.BATCHSERVERCONFIG
truncate table dbo.BATCHSERVERGROUP
truncate table dbo.SYSEMAILPARAMETERS
truncate table dbo.SYSSERVERCONFIG

-- Empty batch history
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Cleaning Batch data...', 10, 1, @currentDateTime) with nowait;

truncate table dbo.BATCHHISTORY;
truncate table dbo.BATCHJOBHISTORY
truncate table dbo.BATCHJOBALERTS
delete from dbo.BATCHJOB where STATUS in (0, 3, 4, 8) -- hold, error, finished and cancelled
delete b from dbo.BATCH b where not exists (select 1 from dbo.BATCHJOB as j where b.BATCHJOBID = j.RECID)

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Deleting batch execution traces...', 10, 1, @currentDateTime) with nowait;

update dbo.BATCHJOB set CREATEDBY = 'Admin'

set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Removing customer usage data...', 10, 1, @currentDateTime) with nowait;

truncate table dbo.SYSLASTVALUE;

-- remove users
set @currentDateTime = convert(varchar, getdate(), 21);
raiserror('%s | Removing original users...', 10, 1, @currentDateTime) with nowait;
truncate table dbo.USERINFO
truncate table dbo.SYSUSERINFO
truncate table dbo.SECURITYUSERROLE
truncate table dbo.PSNUSERINFO