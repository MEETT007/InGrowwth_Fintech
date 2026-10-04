alter table loan_payments add column requested_amount numeric(18,2);
update loan_payments set requested_amount=amount;
alter table loan_payments add column due_date varchar(20);
alter table loans add column closure_certificate boolean not null default false;
alter table loans add column originals_returned boolean not null default false;
alter table loans add column security_released boolean not null default false;
