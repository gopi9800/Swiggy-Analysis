-- Creating Tables
create table fact_orders(
order_id int primary key,
date_id smallint,
location_id smallint,
restaurant_id smallint,
dish_id int,
price numeric(8,2),
rating numeric(2,1),
rating_count smallint,
constraint location_fk_id foreign key(location_id) references dim_location(location_id),
constraint restaurant_fk_id foreign key(restaurant_id) references dim_restaurant(restaurant_id),
constraint dish_fk_id foreign key(dish_id) references dim_dish(dish_id),
constraint date_fk_id foreign key(date_id) references dim_date(date_id)
);

create table dim_restaurant(
restaurant_id smallint primary key,
restaurant_name varchar(100)
);

create table dim_dish(
dish_id int primary key,
category varchar(100),
dish_name varchar(200)
);

create table dim_location(
location_id smallint primary key,
state varchar(100),
city varchar(100),
location varchar(200)
);

create table dim_date(
date_id smallint primary key,
order_date date
);

create table swiggy_data(
State varchar(50),
City varchar(50),
Order_Date date,
Restaurant_Name varchar(100),
Location varchar(200),
Category varchar(100),
Dish_Name varchar(200),
Price_INR float,
Rating float,
Rating_Count int
)

-- Queries

-- Data Validation and checking
-- Null Check

select
sum(case when state is null then 1 else 0 end) as null_state,
sum(case when city is null then 1 else 0 end) as null_city,
sum(case when Order_Date is null then 1 else 0 end) as null_Order_Date,
sum(case when Restaurant_Name is null then 1 else 0 end) as null_Restaurant_Name,
sum(case when Location is null then 1 else 0 end) as null_Location,
sum(case when Category is null then 1 else 0 end) as null_Category,
sum(case when Dish_Name is null then 1 else 0 end) as null_Dish_Name,
sum(case when Price_INR is null then 1 else 0 end) as null_Price_INR,
sum(case when Rating is null then 1 else 0 end) as null_Rating,
sum(case when Rating_Count is null then 1 else 0 end) as null_Rating_Count
from swiggy_data

-- Blank Check

select * from swiggy_data where state = '' or city = '' or Restaurant_Name = ''
or Location = '' or Category = '' or Dish_Name = '' 

-- Duplicates Check

select State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,
Rating_Count,count(*) from swiggy_data group by State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count having count(*) > 1

-- Duplicates Delete
with cte as (
select ctid,*,Row_number() over (partition by State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count order by Order_Date) as rn from swiggy_data)
delete from swiggy_data  where ctid in (select ctid from cte where  rn>1)

-- KPI'S

-- Total Orders
select count(order_id) as total_orders from fact_orders

-- Total Revenue(in millions)
select round((sum(price)/1000000),2) || 'INR Million' as total_revenue from fact_orders

-- Average Dish Price
select round(avg(price),2) as average_dish_price from fact_orders

-- Average Rating
select round(avg(rating),2) as average_rating from fact_orders

-- Deep Drive Business Analysis

-- Monthly Order Trends
select extract (year from Order_Date) as year,extract (month from Order_date)as month,
to_char(Order_Date,'Month') as month_name,count(*) as total_orders from dim_date d
join fact_orders f on d.date_id = f.date_id group by 1,2,3 order by 4 desc

-- Quarterly Order Trends
select extract (year from Order_Date) as year,extract (month from Order_date) as month,
extract(quarter from Order_date) as quarter,count(*) as total_orders from dim_date d
join fact_orders f on d.date_id = f.date_id group by 1,2,3 order by 4 desc

-- Yearly Order Trends
select extract(year from order_date) as year,count(*) as total_orders from dim_date d
join fact_orders f on f.date_id = d.date_id group by 1 order by 2 desc

-- Orders by day of week (mon-sun)
select to_char(order_date,'Day'),count(*) as total_orders from dim_date d join 
fact_orders f on f.date_id = d.date_id group by 1 order by 2 desc

-- Top 10 cities by orders volume
select city,count(*) as total_orders from dim_location d join fact_orders
f on f.location_id = d.location_id group by 1 order by 2 desc limit 10

-- Revenue contribution by states
select state,count(*) as total_orders from dim_location d join fact_orders
f on f.location_id = d.location_id group by 1 order by 2 desc limit 10

-- Top 10 Restaurants by orders volume
select restaurant_name,count(*) as total_orders from dim_restaurant d join fact_orders
f on f.restaurant_id = d.restaurant_id group by 1 order by 2 desc limit 10

-- Top  Food categories by orders volume
select category,count(*) as total_orders from dim_dish d join fact_orders
f on f.dish_id = d.dish_id group by 1 order by 2 desc

-- Top  Food Dishes by orders volume
select dish_name,count(*) as total_orders from dim_dish d join fact_orders
f on f.dish_id = d.dish_id group by 1 order by 2 desc

-- Cusine Performance(Orders + Rating)
select category,count(*) as total_orders,round(avg(rating),2) from fact_orders f 
join dim_dish d on d.dish_id = f.dish_id group by 1 order by 2 desc,3 desc

-- Total Orders by Price Range
select 
case 
when price < 100 then 'Under 100'
when price between 100 and 200 then '100-200'
when price between 200 and 300 then '200-300'
when price between 300 and 400 then '300-400'
when price between 400 and 500 then '400-500'
else '500+' end as price_range,count(*),round(avg(rating),2)
as total_orders from fact_orders group by 1 order by total_orders desc;

-- Rating count distribution
select rating,count(*) as rating_count from fact_orders group by 1 order by 1 desc;