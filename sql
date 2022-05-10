--101, 'Write a block that prints the name of the oldest customer.';
declare 
  v_name varchar2(50);
begin
select last_name||' '||first_name
into v_name
from book_library.customers
where birth_date=(select min(birth_date) from book_library.customers);
dbms_output.put_line(v_name);
end;

--203,'Use the olympics schema. Write a blokk in which declare a procedure. 
--The procedure gets a continent name and an area and lists to the screen the 
--contries which belong to the continent given in the parameter and 
--which area is less than the area given in the parameter. 
--The blokk calls the procedure. Try it out with more values. ';

declare
  procedure proc1 (p_continent olympics.o_countries.continent%type,
                   p_area olympics.o_countries.area%type) is
    begin
    for i in (select *
              from olympics.o_countries
              where continent=p_continent
              and area<p_area)
      loop
       dbms_output.put_line(i.name);
      end loop;
    end;
begin
proc1('Europe',10000000);
dbms_output.put_line('');
proc1('Asia',10000000);
end;

--410','Create a country table in the way that you copy the country table of the olympics schema.
--Then create a view, which shows name, population, capital and population density of 
--South American countries.';
--411,'Try to insert, delete and update rows in the view of the previous task. ';
--412,'Write a trigger, which fires when the view is inserted, updated or deleted. The trigger should perform the DML statement on the table instead of the view or give error when the statement is not good there.  ';

create table my_country as
select * from olympics.o_countries;

create view my_sa_countries as
select name, population, capital, population/area pop_dens 
from my_country
where continent='South America';

/*insert into my_sa_countries(name, population, capital,pop_dens)
values ('DbLand', 2000, 'Db', 2);*/

insert into my_sa_countries(name, population, capital)
values ('DbLand', 2000, 'Db');
commit;
select * from my_sa_countries;
select * from my_country;

delete my_sa_countries;
rollback;

delete my_sa_countries where pop_dens<20;

rollback;

update my_sa_countries
set population=population/100;

rollback;

/*update my_sa_countries
set pop_dens=pop_dens/100;*/

--412,'Write a trigger, which fires when the view is inserted, updated or deleted. 
--The trigger should perform the DML statement on the table instead of the view or 
--give error when the statement is not good there.  ';


create or replace trigger tr_mc
instead of insert or delete on my_sa_countries
for each row
declare
  v_id number(5);
begin
if inserting
    then select nvl(max(c_id),0)+1 into v_id from my_country;
         insert into my_country (c_id, name, population, capital, continent)
         values (v_id, :new.name, :new.population, :new.capital, 'South America');
    elsif deleting
    then delete my_country where name=:new.name;
end if; 
end;
/

insert into my_sa_countries(name, population, capital,pop_dens)
values ('DbLand', 2000, 'Db', 2);

commit;

--'503','Create a stored function, which gets a department_id (from department table of hr schema) 
--and return the record belonging to the id of the department table. 
--If the id does not exist in the table, the function returns with null value. ';

create or replace function f503 (p_dept_id hr.departments.department_id%type) 
    return hr.departments%rowtype is
    v_dept hr.departments%rowtype;
begin
select *
into v_dept
from hr.departments
where department_id=p_dept_id;

return v_dept;

exception
  when no_data_found
  then return null;
end;


--'504','Write a blokk, which lists to the screen the name and salary of the employees 
--whose job_title is ''Programmer'' (you can choose another if it does not exists) 
--and whose salary is less than 5000 (you can choose here a better value). 
--Moreover the blokk writes the name of department to the screen where the emplyoyee works. 
--Use the function of the previous task.';

begin
for i in (select * from hr.employees 
          where job_id in (select job_id from hr.jobs 
                           where job_title='Programmer')
           and  salary<5000)
   loop
     dbms_output.put_line(i.first_name||' '||i.last_name||' '||i.salary||' '||
                          f503(i.department_id).department_name);
   end loop;
end;

--'601','Create a table named Books with attributes: ISBN, title, publisher, year. 
--ISBN is the primary key. Create a table named Book_copies with attributes ID and ISBN. 
--ID is the primary key. ISBN references Books.ISBN.';
--'603','Try out all features of the previous package.';
drop table book_copies;
drop table books;
create table books
(isbn varchar2(30),
title varchar2(50) not null, 
publisher varchar2(30),
year char(4),
constraint book_pk primary key (isbn));

create table book_copies
(id number(5),
isbn varchar2(30) not null, 
constraint bc_pk primary key (id),
constraint bc_fk foreign key (isbn) references books);

--'602','Create a package to manage the two table created previously. 
--The package should contain 
--(1) a public procedure named: add_book, 
---(2) a public function named: remove_book, 
--(3) a public procedure named: list_books, 
--(4) and exceptions named: invalid_book, id_already_taken. 
--The add_book procedure takes ISBN, title, publisher, year, ID as its parameters. 
--First try to insert into the Book table, if the book with the given parameters is already 
--in the Book table, its okay, but if the values do not match throw invalid_book exception. 
--If the book is not in the book table, insert into it. 
--Then insert the values into the Book_copies table. 

--The remove_book function takes an ID as its parameter and 
--removes that copy from Book_copies, 
--then returns the number of remaining copies with the same ISBN. 
--If the ID does not exists in the database, do nothing. 

--List_books procedure lists the books and copies to the screen ';

create or replace package pack_book is
procedure add_book (p_ISBN books.isbn%type, p_title books.title%type, 
                    p_publisher books.publisher%type, p_year books.year%type, 
                    p_ID book_copies.id%type);
function remove_book(p_ID book_copies.id%type) return number;
procedure list_books;
invalid_book exception;
end;
/

create or replace package body pack_book is
procedure add_book (p_ISBN books.isbn%type, p_title books.title%type, 
                    p_publisher books.publisher%type, p_year books.year%type, 
                    p_ID book_copies.id%type) is
  v_b books%rowtype;                    
  begin
   begin
    insert into books(isbn,title, publisher ,year )
    values (p_isbn,p_title, p_publisher ,p_year );
    exception 
      when DUP_VAL_ON_INDEX
      then select * into v_b from books where isbn=p_isbn;
           if p_title!=v_b.title or p_publisher!=v_b.publisher or
              p_year !=v_b.year
              then raise invalid_book;
           end if;
     end;
   insert into book_copies(id,isbn)
   values (p_id, p_isbn);
  end;
function remove_book(p_ID book_copies.id%type) return number is
  v_isbn book_copies.isbn%type;
  v_nu number;
  begin
  select isbn into v_isbn from book_copies where id=p_id;
  delete book_copies where id=p_id;
  select count(*) into v_nu from book_copies where isbn=v_isbn;
  return v_nu;
  end;
procedure list_books is 
  begin
  for i in (select bo.isbn b_isbn, title, publisher, year, id, bc.isbn from books bo full outer join book_copies bc on bo.isbn=bc.isbn)
    loop
    dbms_output.put_line(i.b_isbn||' '||i.title||' '|| i.publisher||' '|| i.year||' '|| i.id);
    end loop;
  end;

end;


begin
pack_book.add_book('124', 'Harry', 'London', '2020', 10);
dbms_output.put_line(pack_book.remove_book(10));
pack_book.list_books;
end;

-------------------------------------------------------------------------------
--102,'Write a block that prints the record of the customer who has two orders. ';
declare
  v varchar2(30);
begin
select cust_first_name|| ' '||cust_last_name
into v
from oe.customers
where customer_id=(select customer_id
                   from oe.orders
                   group by customer_id
                   having count(order_id)=2);
dbms_output.put_line(v);                   
end;   


--103,'Part of the warehouse in Beijingben was destroyed by fire. Write a block that decreases every 
--items quantity in the warehouse by 10. If there are at least 10 of them you should modify the row, 
--otherwise delete the row.';
drop table oe_inventories;
create table oe_inventories as
select * from oe.inventories; /

begin
delete
from oe_inventories 
where warehouse_id =(select warehouse_id
                     from oe.warehouses
                     where warehouse_name='Beijing')
and quantity_on_hand<=10 ;

update oe_inventories 
set quantity_on_hand=quantity_on_hand-10
where warehouse_id =(select warehouse_id
                     from oe.warehouses
                     where warehouse_name='Beijing');
commit;                     
end;
/

select *
from oe_inventories full outer join oe.inventories using(warehouse_id, product_id);

--104,'Write a block which prints to the "screen" how many pieces of product were ordered by each customers. ';
begin
for i in (select cu.customer_id, cust_first_name||' '||cust_last_name cu_name, sum(quantity) nu
          from oe.customers cu left outer join
          oe.orders o on cu.customer_id=o.customer_id
          left outer join 
          oe.order_items oi on o.order_id=oi.order_id
          group by cu.customer_id, cust_first_name, cust_last_name)
loop          
dbms_output.put_line(i.customer_id||', '||i.cu_name||', '||i.nu);
end loop;
end;
/


--201,'Write a block with a function declared in it. The function takes two arguments: 
--a customer id and a product id. The function returns the amount the customer has ordered of the product. 
--Call the function for every customer with a last name starting with ''T'' and 
--for every item with less than 500 list price, then print the customer''s name, the product''s name, 
--and the ordered amount to the screen.';
declare
  v_nu number(12);
  function f201 (p_customer_id oe.customers.customer_id%type, 
                 p_product_id oe.product_information.product_id%type) return number is
                 v number(12);
                 begin
                 select sum(quantity) into v
                 from oe.order_items
                 where product_id=p_product_id
                 and order_id in (select order_id from oe.orders
                                  where customer_id=p_customer_id);
                 return v;
                 end;
begin
for i in (select customer_id, cust_first_name||' '||cust_last_name cu_name from oe.customers 
          where cust_last_name like 'T%')
  loop
    for j in (select product_id, product_name from oe.product_information where list_price<500) 
     loop
      v_nu:=f201(i.customer_id, j.product_id);
      if v_nu!=0 then 
         dbms_output.put_line(i.cu_name||', '||j.product_name||', '||v_nu);
      end if;
     end loop;
  end loop;
end;


--301,'Write a block with a function declaration. The function takes a customer name as parameter 
--and returns how many order have been placed by the customer. 
--Call the function inside the block with customer names (a) who have not yet placed any order, 
--(b) who have placed more than one order, 
--(c) who is not in the customer table. 
--Execute the block, handle every exception and print the error code and error message.';
declare
  function f301(p_cust_first_name oe.customers.cust_first_name%type, 
                p_cust_last_name oe.customers.cust_first_name%type) return number is
   v number(4);             
   begin
   select count(order_id)
   into v
   from oe.orders
   where customer_id=(select customer_id 
                     from oe.customers
                     where cust_first_name=p_cust_first_name
                     and cust_last_name=p_cust_last_name);
   return v;                     
   end;
begin
dbms_output.put_line(f301('Hema','Powell'));
dbms_output.put_line(f301('John','Smith'));
dbms_output.put_line(f301('Elia','Fawcett'));
exception when others then dbms_output.put_line(sqlcode||' '||sqlerrm);
end;
/
--select * from oe.customers;


--303','Write a block, that calls the previously defined procedure. 
--Call it in a way that it will raise exception. Examine the results. 
--Extend the block to handle exceptions caused by the select into statement and prints the error.';

declare 
v_date_of_birth oe.customers.date_of_birth%type;
v_gender oe.customers.gender%type;
begin
proc302('John','Smith',v_date_of_birth, v_gender);
dbms_output.put_line(to_char(v_date_of_birth,'yyyy.mm.dd')||' '||v_gender);
exception when no_data_found or too_many_rows
then dbms_output.put_line(sqlcode||' '||sqlerrm);
end;
/
select cust_first_name
from oe.customers
group by cust_first_name
having count(*)>1;

--304,'Create a table named familymembers with two attributes: customer table id (foreign key), 
--familymember name. The primary key is the two attribute combined.';
drop table familymembers;
create table familymembers
(customer_id number(6),
familymember_name varchar2(30),
constraint fm_pk primary key (customer_id,familymember_name));


--305,'Write a stored function which inserts a row into the previously created table. 
--The function gets two parameters: a customer id and a family member name. 
--If the insert statement was successful the function returns with the name of the customer. 
--If an exception has been raised (because the given family member name already exists in table 
--for the current customer), the function handles it: write to the screen the customer''s name 
--and the family member''s name, then the function return with NULL.';
create or replace function f305 (p_customer_id familymembers.customer_id%type,
                                 p_familymember_name familymembers.familymember_name%type) 
                                 return varchar2 is
v_name varchar2(30);                                 
begin
select cust_first_name||' '||cust_last_name
into v_name
from oe.customers
where customer_id=p_customer_id;


insert into familymembers(customer_id,familymember_name)
values (p_customer_id,p_familymember_name);

return v_name;
exception
  when dup_val_on_index
  then dbms_output.put_line(v_name||' '|| p_familymember_name );
       return null;
end;

begin
dbms_output.put_line(f305 (144,'Anna'));
end;                                 

--select * from oe.customers;

--306,'Write a stored procedure, which gets a customer''s name and a family member''s name as parameters. 
--Call the previously created function from the procedure with the parameters. 
--Write the value return by the function to the screen.';
create or replace procedure proc306(p_cust_first_name oe.customers.cust_first_name%type, 
                p_cust_last_name oe.customers.cust_first_name%type,
                p_familymember_name familymembers.familymember_name%type) is
v_cust_id oe.customers.customer_id%type;                 
begin
select customer_id
into v_cust_id
from oe.customers
where cust_first_name=p_cust_first_name
and cust_last_name=p_cust_last_name;

dbms_output.put_line(f305 (v_cust_id,p_familymember_name));

end;
                
                
--307,'Write a block that calls the previously created procedure with null value for family member name. 
--Handle the exception and write to the screen that no family member name was given. 
--Within the same block, call the procedure with a customer name that does not exist in the customer table. 
--Handle the exception and write to the screen that no customer has been registered with the given id. 
--Moreover, call the procedure with a customer name that is not unique (that is, more than one customers 
--exist in the customers table with that name), handle the exception in the same way as earlier. 
--Separated exception handlers should be used, one for each case above.';

begin
  declare
    m_ex exception;
    pragma exception_init(m_ex, -1400);
  begin
   proc306('Elia','Fawcett',null);

  exception 
    when m_ex then dbms_output.put_line('no family members');
  end;

  begin
   proc306('John','Smith','Anna');
    exception when no_data_found then dbms_output.put_line('no customer');
   end;
   
   begin
   proc306('Anna','Smith','Anna');
    exception when too_many_rows then dbms_output.put_line('more customers');
   end;
end;                
