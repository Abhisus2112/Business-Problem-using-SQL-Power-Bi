create database Affine_new;
use Affine_new;

select * from engagementdata;
select * from aquisitioncost;
select * from percommunicationmodecost;


-------------------------------------------------------------------------
							----Data Cleaning----	
-------------------------------------------------------------------------

--Change the datatype of Date column from datetime to date
ALTER TABLE engagementdata ALTER COLUMN Date date not null;



-- Updating the average value with in [Spends ($)] column where outlier found.
update engagementdata
set [Spends ($)] = (
select cast(avg([Spends ($)]) as numeric(36,2))
from engagementdata
where [Spends ($)] <> '1000000000')
where [Spends ($)] = '1000000000'


-- Now updating the Mode value with in [Total Playtime] column where outlier found.
update engagementdata
set [Total Playtime] = (select cast(avg([Total Playtime]) as numeric(36,2))
from engagementdata
where [Total Playtime] not in ('-99', '99999999'))
where [Total Playtime] in ('-99', '99999999')


--Updating [Online Playtime] with [Total Playtime] where [Online Playtime]>[Total Playtime]
update engagementdata
set [Online Playtime]=[Total Playtime]
where [Online Playtime]>[Total Playtime]

--Updating [Online Playtime] with Mean value where [Online Playtime] = '-99'
update engagementdata
set [Online Playtime] = (
select cast(round(AVG([Online Playtime]),2) as numeric(36,2))
from engagementdata
where [Online Playtime]<>'-99')
where [Online Playtime]='-99'


--Updating year of date column with 2019 where value is 1900
update engagementdata
set date = '2019-01-01'
where date = '1900-01-01'

--Updating month column with 201901 where value is 190001
update aquisitioncost
set month = '201901'
where month = '190001'

--Updating Mode value as it is categorical column where [Mode of Communication] is Blank
update aquisitioncost
set [Mode of Communication] = (
select [Mode of Communication]
from(
select [Mode of Communication], count(*) total_count, DENSE_RANK() over (order by count(*) desc) rnk
from aquisitioncost
group by [Mode of Communication]) a
where a.rnk = 1)
where [Mode of Communication] = '';


--Updating column Mode of Cummunication in aquisitioncost table.
update aquisitioncost
set [Mode of Communication] = 'Mail'
where [Mode of Communication] = 'MaiL'

update aquisitioncost
set [Mode of Communication] = 'WeChat'
where [Mode of Communication] = 'WeChAt'


--Updating column Mode of Cummunication in PerCommunicationCost table.
update percommunicationmodecost
set [Mode of Communication] = 'Mail'
where [Mode of Communication] = 'Mail'

update percommunicationmodecost
set [Mode of Communication] = 'YouTube'
where [Mode of Communication] = 'YOuTube'

update percommunicationmodecost
set [Mode of Communication] = 'WeChat'
where [Mode of Communication] = 'WEChat'

--Update column month from table AquisitionCost
update aquisitioncost
set Month = RIGHT(Month,2)




----------------------------------------------------------------------------
----------------------------------------------------------------------------
--EDA Analysis--

--Univariate Analysis--

/*Below query is showing the total number of user based on genre. The below output is showing 
Most of the people are playing Action Adventure*/
select [Playtime Genre], count(*) Total_count
from EngagementData
group by [Playtime Genre]
order by count(*) desc

/*Below query is showing the total number of user based on Sepnding Category. The below output is showing 
Most of the people are playing Game only*/
select [Spend Category], count(*) Total_count
from EngagementData
group by [Spend Category]
order by count(*) desc;

--Below query is showing the total number of game purchase using Digitally and Physically.  
select *
from (select Case when [Digital Purchase] = 'NA' then 'Not Purchasing'
when [Digital Purchase] = '1' Then 'Digitally Purchase'
when [Digital Purchase] = '0' then 'Physically Purchase'
end Purchase, count(*) Total_Count
from EngagementData
group by [Digital Purchase])a
where a.Purchase <> 'Not Purchasing'
order by a.Total_Count desc;

--Revenue Analysis
select Max([Spends ($)]) [Maximum Revenue ($)], Min([Spends ($)]) [Minimum Revenue ($)], AVG([Spends ($)]) [Mean Revenue ($)]
from EngagementData;

--Total Playtime Analysis
select Max([Total Playtime]) [Maximum Time (hr)], Min([Total Playtime]) [Minimum Time (hr)], 
AVG([Total Playtime]) [Mean Time (hr)]
from EngagementData;

--Online Playtime Analysis
select Max([Online Playtime]) [Maximum Time (hr)], Min([Online Playtime]) [Minimum Time (hr)], AVG([Online Playtime]) [Mean Time (hr)]
from EngagementData



--Bivariate Analysis--
-- Checking monthwise spends.
select month(date) Month, Sum([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by month(date)
order by month(date);

-- Checking monthwise spends where not purchasing.
select month(date) Month, Sum([Spends ($)]) [Total Revenue ($)]
from EngagementData
where [Digital Purchase] = 'NA' and [Physical Purchase] = 'NA'
group by year(date), month(date)
order by year(date), month(date);

-- Checking monthwise spends where purchasing games digitally or Physically.
select month(date) Month, Sum([Spends ($)]) [Total Revenue ($)]
from EngagementData
where [Digital Purchase] = '1' or [Physical Purchase] = '1'
group by year(date), month(date)
order by year(date), month(date);


/*The below output is showing that how much total time is spent on games monthly basis. 
It has clearly shown that in the month of January, players spent most of the time playing games*/
select Month(date) Month, SUM([Total Playtime]) [Total Playtime (hr)]
from EngagementData
group by Month(date)
order by Month(date)


/*The below output is showing on an average players spent how many time on games on monthly*/
select Month(date) Month, Avg([Total Playtime]) Average_Playtime
from EngagementData
group by Month(date)
order by Month(date)

-- Checking monthly spending time on game where not purchasing.
select month(date) Month, Sum([Total Playtime]) [Total Playtime (hr)]
from EngagementData
where [Digital Purchase] = 'NA' and [Physical Purchase] = 'NA'
group by month(date)
order by month(date);

-- Checking monthly spending time where purchasing games digitally or Physically.
select month(date) Month, Sum([Total Playtime]) [Total Playtime (hr)]
from EngagementData
where [Digital Purchase] = '1' or [Physical Purchase] = '1'
group by month(date)
order by month(date);


/*The below output is showing that how much total time the players are spending time Online & Offline. 
It has clearly shown that in the month of January, players spent most of the time playing games 
online and in August they spent most of the time playing games offline. And the trends 
clearly told that players are spending most of the time in offline*/

select Month(date) Month, Cast(SUM([Online Playtime]) as numeric(36,2)) [Total Online Playtime (hr)],
cast(Sum([Total Playtime] - [Online Playtime]) as numeric(36,2)) [Total Offline Playtime (hr)]
from EngagementData
group by Month(date)
order by Month(date)

/*The below output is showing on an average players spent how many time on online and offline games on monthly*/
select Year(Date) Year, Month(date) Month, Cast(Avg([Online Playtime])as numeric(36,2)) Average_Online_Playtime, 
cast(Avg([Total Playtime] - [Online Playtime]) as numeric(36,2)) Average_Offline_Playtime
from EngagementData
group by Year(Date), Month(date)
order by Year(Date), Month(date)

--Monthly Online & Offline Time trends where players are not purchasing any game.
select Month(date) Month, Cast(SUM([Online Playtime]) as numeric(36,2)) [Total Online Playtime (hr)],
cast(Sum([Total Playtime] - [Online Playtime]) as numeric(36,2)) [Total Offline Playtime (hr)]
from EngagementData
where [Digital Purchase] = 'NA' and [Physical Purchase] = 'NA'
group by month(date)
order by month(date);


-- Checking monthly spending time on Online and Offline game where not purchasing.
select Month(date) Month, Cast(SUM([Online Playtime]) as numeric(36,2)) [Total Online Playtime (hr)],
cast(Sum([Total Playtime] - [Online Playtime]) as numeric(36,2)) [Total Offline Playtime (hr)]
from EngagementData
where [Digital Purchase] = '1' or [Physical Purchase] = '1'
group by month(date)
order by month(date);



/*The below output is showing that how much total time is spent on games based on Genre. 
It has clearly shown that players spent most of the time on shooter game*/
select [Playtime Genre], SUM([Total Playtime]) [Total Playtime (hr)]
from EngagementData
group by [Playtime Genre]
order by sum([Total Playtime]) desc

/*The below output is showing on an average players spent how many times on which genre*/
select [Playtime Genre], cast(Avg([Total Playtime]) as numeric(36,2)) Average_Playtime
from EngagementData
group by [Playtime Genre]
order by [Playtime Genre]


/*The below output is showing that how much total time spent on online games genre. 
It has clearly shown that in the month of January, players spent most of the time playing games 
online and in July they spent most of the time playimg games offline. And the trends 
clearly told that players are spending most of the time in offline*/

select [Playtime Genre], Cast(SUM([Online Playtime]) as numeric(36,2)) [Total Online Playtime (hr)],
cast(Sum([Total Playtime] - [Online Playtime]) as numeric(36,2)) [Total Offline Playtime (hr)]
from EngagementData
group by [Playtime Genre]
order by [Playtime Genre]

/*The below output is showing on an average players spent how many time on online and offline games based on Playtime Genre*/
select [Playtime Genre], Cast(Avg([Online Playtime])as numeric(36,2)) Average_Online_Playtime, 
cast(Avg([Total Playtime] - [Online Playtime]) as numeric(36,2)) Average_Offline_Playtime
from EngagementData
group by [Playtime Genre]
order by [Playtime Genre]


/*The below output is showing the revenue generating by the users on which genre*/

select [Playtime Genre], SUM([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by [Playtime Genre]
order by SUM([Spends ($)]) desc

/*The below output is showing the revenue generating by the users on which genre where users are not purchasing game*/

select [Playtime Genre], SUM([Spends ($)]) [Total Revenue ($)]
from EngagementData
where [Digital Purchase] = 'NA' and [Physical Purchase] = 'NA'
group by [Playtime Genre]
order by SUM([Spends ($)]) desc

/*The below output is showing the revenue generating by the users on which genre where users are purchasing game*/

select [Playtime Genre], SUM([Spends ($)]) [Total Revenue ($)]
from EngagementData
where [Digital Purchase] = '1' or [Physical Purchase] = '1'
group by [Playtime Genre]
order by SUM([Spends ($)]) desc

/*The below output is showing the revenue generating by the users on which spending category*/

select [Spend Category], SUM([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by [Spend Category]
order by SUM([Spends ($)]) desc;

--Total expenditure of company based on Communication Mode.
select a.[Mode of Communication], Sum(#Times_communicated*[Cost (in Cents)]) [Total Cost ($)]
from aquisitioncost a
join PerCommunicationModeCost p
on a.[Mode of Communication] = p.[Mode of Communication]
group by a.[Mode of Communication]
order by Sum(#Times_communicated*[Cost (in Cents)]) desc;


--Below query is showing time of communication based on Mode of Communication

select [Mode of Communication] as [Mode of Communication], Sum(#Times_communicated) Total_Count_of_communication
from aquisitioncost
group by [Mode of Communication];


--Top 10 customer based on Playtime
with cte1 as(
select Acct_ID, SUM([Total Playtime]) [Total Playtime (hr)], rank() over(order by SUM([Total Playtime]) desc) rnk
from EngagementData
group by Acct_ID)

select Acct_ID, [Total Playtime (hr)]
from cte1
where rnk between 1 and 10;

--Top 10 customer based on Online Playtime
with cte1 as(
select Acct_ID, Cast(SUM([Online Playtime]) as numeric(36,2)) [Total Online Playtime (hr)], rank() over(order by SUM([Online Playtime]) desc) rnk
from EngagementData
group by Acct_ID)

select Acct_ID, [Total Online Playtime (hr)]
from cte1
where rnk between 1 and 10;

--Top 10 customer based on Offline Playtime
with cte1 as(
select Acct_ID, Cast(SUM([Total Playtime]-[Online Playtime]) as numeric(36,2)) [Total Offline Playtime (hr)], 
rank() over(order by SUM([Total Playtime]-[Online Playtime]) desc) rnk
from EngagementData
group by Acct_ID)

select Acct_ID, [Total Offline Playtime (hr)]
from cte1
where rnk between 1 and 10;

--Top 10 customer based on Revenue
with cte1 as(
select Acct_ID, SUM([Spends ($)]) [Total Revenue ($)], rank() over(order by SUM([Spends ($)]) desc) rnk
from EngagementData
group by Acct_ID)

select Acct_ID, [Total Revenue ($)]
from cte1
where rnk between 1 and 10;

--Top 10 Dates based on Revenue
with cte1 as(
select date, SUM([Spends ($)]) [Total Revenue ($)], rank() over(order by SUM([Spends ($)]) desc) rnk
from EngagementData
group by date)

select date, [Total Revenue ($)]
from cte1
where rnk between 1 and 10;


--Top 10 customer where company spending money more.

with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) [Cost ($)]
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) [Revenue ($)]
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, [Cost ($)], [Revenue ($)], ([Revenue ($)]-[Cost ($)]) [Profit ($)], rank() over(order by [Cost ($)] desc) rnk
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id)

select Acct_id, [Cost ($)]
from cte4
where rnk between 1 and 10

--Top 10 customer based on Profit.

with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) [Cost ($)]
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) [Revenue ($)]
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, [Cost ($)], [Revenue ($)], ([Revenue ($)]-[Cost ($)]) [Profit ($)], 
rank() over(order by ([Revenue ($)]-[Cost ($)]) desc) rnk
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id)

select Acct_id, [Profit ($)]
from cte4
where rnk between 1 and 10;



--Below query is showing expenditure based on mode of communication

select a.[Mode of Communication], Sum(#Times_communicated*[Cost (in Cents)]) [Total Cost ($)]
from aquisitioncost a
join PerCommunicationModeCost p
on a.[Mode of Communication] = p.[Mode of Communication]
group by a.[Mode of Communication]
order by Sum(#Times_communicated*[Cost (in Cents)]) desc;

--Month-wise cost and Revenue
with cte1 as(
select Month, Sum(#Times_communicated*[Cost (in Cents)]) Cost
from AquisitionCost a
join PerCommunicationModeCost p
on a.[Mode of Communication] = p.[Mode of Communication]
group by Month),

cte2 as(
select Month(Date) Month, Sum([Spends ($)]) Revenue
from engagementdata
group by Month(Date))

select c1.Month, Revenue, Cost, (Revenue-Cost) Profit
from cte1 c1
join cte2 c2
on c1.Month = c2.Month
order by c1.Month




--Creating table on Cost, Revenue and Profit
with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) [Cost ($)]
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) [Revenue ($)]
from EngagementData
group by Acct_ID)

select c1.Acct_id, [Cost ($)], [Revenue ($)], ([Revenue ($)]-[Cost ($)]) [Profit ($)]
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id
order by c1.Acct_id

----------------------




--Questions Part-1


/*What is the favorite genre in terms of playtime?*/

with cte1 as(
select [Playtime Genre], SUM([Total Playtime]) [Total_Playtime (hr)], rank() over(order by SUM([Total Playtime]) desc) rnk
from EngagementData
group by [Playtime Genre])

select [Playtime Genre], [Total_Playtime (hr)]
from cte1
where rnk = 1;


/*What is the genre on which the users spend most?*/

with cte1 as(
select [Playtime Genre], SUM([Spends ($)]) [Total Revenue ($)], rank() over(order by SUM([Spends ($)]) desc) rnk
from EngagementData
group by [Playtime Genre]
)

select [Playtime Genre], [Total Revenue ($)]
from cte1
where rnk = 1

--Is this changing over time?
--The below query is showing the date-wise genre where users spend the most and the output is clearly showing that it is changing over time
with cte1 as(
select month(date) Month,[Playtime Genre], SUM([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by month(date),[Playtime Genre]),

cte2 as(
select *, rank() over (Partition by Month order by [Total Revenue ($)] desc) rnk
from cte1)

select Month, [Playtime Genre],[Total Revenue ($)]
from cte2
where rnk = 1;


--The below query is showing the month-wise genre where users spend the most of the playtime and the output is clearly showing that it is changing over time
with cte1 as(
select month(date) Month,[Playtime Genre], SUM([Total Playtime]) [Total Playtime (hr)]
from EngagementData
group by month(date),[Playtime Genre]),

cte2 as(
select *, rank() over (Partition by Month order by [Total Playtime (hr)] desc) rnk
from cte1)

select Month, [Playtime Genre], [Total Playtime (hr)]
from cte2
where rnk = 1


--Do players buy games physically or digitally more?
--The output is clearly showing that most of the users are purchasing game digitally.

With cte1 as(
select *
from (select Case when [Digital Purchase] = 'NA' then 'Not Purchasing'
when [Digital Purchase] = '1' Then 'Digitally Purchase'
when [Digital Purchase] = '0' then 'Physically Purchase'
end Purchase, count(*) Total_Count
from EngagementData
group by [Digital Purchase])a
where a.Purchase <> 'Not Purchasing'),

cte2 as(
select *, rank() over(order by Total_Count desc) rnk
from cte1)

select Purchase, Total_Count
from cte2
where rnk = 1;


--The below query is showing spend distribution over purchase.

select *
from (select Case when [Digital Purchase] = 'NA' then 'Not Purchasing'
when [Digital Purchase] = '1' Then 'Digitally Purchase'
when [Digital Purchase] = '0' then 'Physically Purchase'
end Purchase, sum([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by [Digital Purchase])a
where a.Purchase <> 'Not Purchasing'
order by a.[Total Revenue ($)] desc;



--Is this changing over time?
--Below output is clearly showing that it is changing over time.
with cte1 as(
select *
from (select month(date) Month, Case when [Digital Purchase] = 'NA' then 'Not Purchasing'
when [Digital Purchase] = '1' Then 'Digitally Purchase'
when [Digital Purchase] = '0' then 'Physically Purchase'
end Purchase, sum([Spends ($)]) [Total Revenue ($)]
from EngagementData
group by month(date),[Digital Purchase])a
where a.Purchase <> 'Not Purchasing'),

cte2 as(
select *, rank() over(Partition by Month order by [Total Revenue ($)] desc) rnk
from cte1)

select Month, purchase, [Total Revenue ($)]
from cte2
where rnk = 1;


--Part 2

--Create SPH column and Bucket
with cte1 as(
select *, cast([Spends ($)]/[Total Playtime] as numeric(36,2)) SPH
from EngagementData)

select *, case when SPH >= 1 and SPH <= 5 then '1-5'
when SPH> 5 and SPH<=10 then '6-10'
when SPH> 10 and SPH<=15 then '11-15'
else '15+'
end Bucket
from cte1;









--Part 3
-- What is the Overall ROI?
with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) Cost
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) Revenue
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, Cost, Revenue, (Revenue-Cost) Profit
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id),

cte5 as(
select SUm(Revenue) Total_Revenue, Sum(Cost) Total_Cost, Sum(Profit) Total_Profit
from cte4)

select cast(((Total_Revenue-Total_Cost)/Total_Cost)*100 as numeric(36,2)) ROI
from cte5;



--Positive ROI--
--What is the Players distribution where ROI is Positive?
with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) Cost
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) Revenue
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, Cost, Revenue, (Revenue-Cost) Profit
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id)

select Acct_id, (((Revenue-Cost)/Cost)*100) ROI
from cte4
where (((Revenue-Cost)/Cost)*100) >0
order by (((Revenue-Cost)/Cost)*100) desc;



--Break-Even-Point--
--What is the Players distribution where ROI is in Break-Even-Point?
with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) Cost
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) Revenue
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, Cost, Revenue, (Revenue-Cost) Profit
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id)

select Acct_id, Revenue, Cost, Profit, (((Revenue-Cost)/Cost)*100) ROI
from cte4
where (((Revenue-Cost)/Cost)*100) = 0
order by Acct_id;


--Negetive ROI--
--What is the Players distribution where ROI is Negetive?
with cte1 as(
select acct_id, [Mode of Communication],Sum(#Times_communicated) Total_Communication
from AquisitionCost
group by acct_id,[Mode of Communication]),

cte2 as (
select Acct_id, Sum(Total_Communication*[Cost (in Cents)]) Cost
from cte1 c
join PerCommunicationModeCost p
on c.[Mode of Communication] = p.[Mode of Communication]
group by Acct_id),

cte3 as(
select Acct_ID, sum([Spends ($)]) Revenue
from EngagementData
group by Acct_ID),

cte4 as(
select c1.Acct_id, Cost, Revenue, (Revenue-Cost) Profit
from cte2 c1
join cte3 c3
on c1.acct_id = c3.acct_id)

select Acct_id, (((Revenue-Cost)/Cost)*100) ROI
from cte4
where (((Revenue-Cost)/Cost)*100) < 0
order by Acct_id;





with cte1 as(
select *, cast([Spends ($)]/[Total Playtime] as numeric(36,2)) SPH
from EngagementData),

cte2 as(
select *, case when SPH >= 1 and SPH <= 5 then '1-5'
when SPH> 5 and SPH<=10 then '6-10'
when SPH> 10 and SPH<=15 then '11-15'
else '15+'
end Bucket
from cte1)

select date,Acct_ID, Bucket,[Playtime Genre],SUM([Total Playtime]) Total_Playtime, SUM([Spends ($)]) Total_Revenue
from cte2
group by date, Acct_ID, Bucket,[Playtime Genre];




















