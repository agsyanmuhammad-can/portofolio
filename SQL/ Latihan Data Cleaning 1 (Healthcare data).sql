/*
 * Dataset bersumber dari kaggle berjudul 'Healthcare Data Cleaning Series (Easy)' 
 * dari tautan https://www.kaggle.com/datasets/nudratabbas/healthcare-data-cleaning-series-easy/data 
 */

-- Membuat Tabel kotor
create table health_kotor (
	patient_id int,
	full_name varchar(100),
	gender varchar(6),
	date_of_birth varchar(25), --format tanggal masih kotor sehingga tipe data belum berbentuk date
	phone varchar(20), --agar angka nol tetap terbaca jika nomor diawali nol
	email varchar(50),
	city varchar(25),
	state varchar(25),
	zip_code varchar(15),
	insurance_provider varchar(25),
	registration_date varchar(25) --format tanggal masih kotor sehingga tipe data belum berbentuk date
);

-- Input data csv ke dalam tabel
copy health_kotor
FROM 'D:\Downloads\Dataset Kaggle\Cleaning Exercise SQL\patients_easy.csv' DELIMITER ',' CSV header;

-- membuat tabel copy yang akan dicleaning
CREATE TABLE health_cleaning AS
SELECT * FROM health_kotor;

-- melihat isi tabel
select *
from health_cleaning
limit 10;

-- Mengecek data NULL
select 
	count(*) as total_baris,
	sum(case when patient_id is null then 1 else 0 end) as null_patient_id,
	sum(case when full_name is null then 1 else 0 end) as null_full_name,
	sum(case when gender is null then 1 else 0 end) as null_gender,
	sum(case when date_of_birth is null then 1 else 0 end) as null_datebirth,
	sum(case when phone is null then 1 else 0 end) as null_phone,
	sum(case when email is null then 1 else 0 end) as null_email,
	sum(case when email is null then 1 else 0 end) as null_city,
	sum(case when state is null then 1 else 0 end) as null_state,
	sum(case when zip_code is null then 1 else 0 end) as null_zip_code,
	sum(case when insurance_provider is null then 1 else 0 end) as null_insurance_provider,
	sum(case when registration_date is null then 1 else 0 end) as null_registration_date
from health_cleaning;
/*
 * kolom yang memiliki nilai null, diantaranya:
 * date_of_birth = 21 nilai (dibiarkan null karena ingin cleaning format tanggal)
 * phone = 38 nilai (diubah menjadi N/A)
 * email = 23 nilai (diupdate menjadi alamat email)
 * city = 23 nilai (diupdate menjadi N/A)
 * insurance_provider = 19 nilai (diupdate menjadi N/A)
 */

-- Cek Null
select patient_id, full_name, date_of_birth, phone, email, city, insurance_provider
from health_cleaning
where date_of_birth is null or phone is null or email is null or city is null or insurance_provider is null;

-- Update email (asumsi bahwa nama email adalah gabungan nama depan dan nama belakang dan menggunakan gmail)
update health_cleaning
set email = concat(split_part(full_name,' ',1),'.',split_part(full_name,' ',2), '@gmail.com')
where email is null;

-- Update phone dengan N/A
update health_cleaning
set phone = 'N/A'
where phone is null;

-- Update city dengan N/A
update health_cleaning
set city = 'N/A'
where city is null;

-- Update insurance_provider
update health_cleaning
set insurance_provider = 'N/A'
where insurance_provider is null;

-- Cek Null kembali
select patient_id, full_name, date_of_birth, phone, email, city, insurance_provider
from health_cleaning
where date_of_birth is null or phone is null or email is null or city is null or insurance_provider is null;


-- mengecek data duplikat berdasarkan patient_id
select patient_id, count(*) as jumlah_duplikat
from health_cleaning
group by patient_id
having count(*) > 1; -- kolom patient_id memiliki 32 data duplikat

-- mengecek duplikat berdasarkan baris
select 	patient_id,
	full_name,
	gender,
	date_of_birth,
	phone,
	email,
	city,
	state,
	zip_code,
	insurance_provider,
	registration_date, 
	count(*) as jumlah_duplikat
from health_cleaning
group by patient_id,
	full_name,
	gender,
	date_of_birth,
	phone,
	email,
	city,
	state,
	zip_code,
	insurance_provider,
	registration_date
HAVING count(*) > 1; -- lalu data duplikat yang 100% sama berjumlah 24

WITH DuplicateGroups AS ( 
 select patient_id, count(*) as jumlah_duplikat
from health_cleaning
group by patient_id
having count(*) > 1
) 
select h.* 
FROM health_cleaning h 
JOIN DuplicateGroups d 
 ON h.patient_id = d.patient_id;


-- mengecek data mana yang duplikatnya hanya patient_id bukan seluruh baris
with tabel1 as(
select patient_id, count(*) as jumlah_duplikat
from health_cleaning
group by patient_id
having count(*) > 1 -- kolom patient_id memiliki 32 data duplikat
),
tabel2 as(
select 	patient_id,
	full_name,
	gender,
	date_of_birth,
	phone,
	email,
	city,
	state,
	zip_code,
	insurance_provider,
	registration_date, 
	count(*) as jumlah_duplikat
from health_cleaning
group by patient_id,
	full_name,
	gender,
	date_of_birth,
	phone,
	email,
	city,
	state,
	zip_code,
	insurance_provider,
	registration_date
HAVING count(*) > 1 -- lalu data duplikat yang 100% sama seluruh kolom berjumlah 24
)
SELECT patient_id
FROM tabel1
EXCEPT
SELECT patient_id
FROM tabel2;

--

-- cek ulang
select max(patient_id) as id_terbaru, count(patient_id) as jumlah_pasien
from health_cleaning;


-- Menghapus duplicate row
BEGIN; -- memulai operasi penghapusan

WITH duplicate_rows AS (
    SELECT
        ctid,
        ROW_NUMBER() OVER (
            PARTITION by h.*
            ORDER BY ctid
        ) AS row_num
    FROM health_cleaning as h
)
DELETE FROM health_cleaning as h
WHERE ctid IN (
    SELECT ctid
    FROM duplicate_rows
    WHERE row_num > 1
)
RETURNING *; --Cek value yang dihapus sudah benar atau belum

COMMIT; -- Run jika hasil penghapusan sudah benar
-- ROLLBACK; -- jika hasil penghapusan tidak sesuai


-- mengecek duplikat patient_id lagi
select max(patient_id) as id_terbaru, count(patient_id) as jumlah_pasien
from health_cleaning;

select patient_id, count(*) as jumlah_duplikat
from health_cleaning
group by patient_id
having count(*) > 1 -- sekarang tinggal menyisakan 8 duplikat
order by patient_id;

-- melihat 8 data patient_id yang duplikat
select * from health_cleaning t1
where (select count(*) from health_cleaning t2
where t2.patient_id = t1.patient_id) > 1
order by patient_id;

/*
 * breakdown:
 * 8 patient_id yang duplikat, yaitu:
 * 1. patient_id 99 (April Little dan Christopher Barr)
 * 2. patient_id 132 (Tyler Hall dan Mr. Micheal Evans)
 * 3. patient id 137 (Monica Nielsen dan Brian Hampton
 * 4. patient_id 335 (Heidi Ferguson dan Marc Lopez)
 * 5. patient_id 404 (Christine Watson dan Kathleen Arnold)
 * 6. patient_id 435 (Adam Smith and Laura Gonzalez)
 * 7. patient_id 475 (Meghan Peterson dan Leroy Thomas)
 * 8. patient_id 484 (John Clrak dan Charles Stephenson)
 */

-- Apakah ada kasus duplikat lain? seperti nama hingga registration_date sama tapi patient_id berbeda
select
	full_name, gender, date_of_birth, phone, email, city, state, zip_code, insurance_provider, registration_date, 
	count(*) as jumlah_duplikat
from health_cleaning
group by
	full_name, gender, date_of_birth, phone, email, city, state, zip_code, insurance_provider, registration_date
HAVING count(*) > 1; -- ternyata ada 8 baris yang indetik 100% tapi memiliki patient_id yang berbeda

WITH DuplicateGroups AS ( 
 select full_name, count(*) as jumlah_duplikat
from health_cleaning
group by full_name
having count(*) > 1
) 
select h.* 
FROM health_cleaning h 
JOIN DuplicateGroups d 
 ON h.full_name = d.full_name
order by full_name; -- di sini ternyata terdapat 10 nama sama bukan hanya 8
/*
 * breakdown:
 * 8 nama dengan seluruh value indentik tetapi memiliki patient_id berbeda, yaitu: (perlu dihapus)
 * 1. April Little (id 249 dan 99)
 * 2. Christine Watson (id 404 dan 564)
 * 3. John Clark (id 218 dan 484)
 * 4. Laura Gonzales (id 290 dan 435)
 * 5. Leroy Thomas (id 386 dan 475)
 * 6. Marc Lopez (id 335 dan 410)
 * 7. Monica Nielsen (id 137 dan 326)
 * 8. Mr. Micheal Evans (id 132 dan 397)
 * 
 * 2 nama dengan nama identik tapi value lainnya berbeda (tidak perlu dihapus karena sangat mungkin dua atau lebih orang memiliki nama yang sama)
 * 1. Michael Evans id 15 dan 134 berbeda isi (contoh date_of_birth)
 * 2. Michael Gill id 383 dan 258 berbeda isi (contoh date_of_birth)
 */

select * from health_cleaning t1
where (select count(*) from health_cleaning t2
where t2.full_name = t1.full_name) > 1
order by patient_id;

select *
from health_cleaning
where full_name = 'Laura Gonzalez';

-- Menangani patient_id yang duplikat 
/*
 * dari 8 patient_id yang duplikat dan 8 nama yang datanya duplikat identik, ditemukan irisan sebagai berikut:
 *patient_id | full_name
 *99 | April Little
 *132 | Mr. Michael Evans
 *137 | monica nielsen
 *335 | Marc Lopez
 *404 | Christine Watson
 *435 | Laura Gonzalez
 *475 | Leroy Thomas
 *484 | John Clark
 *data inilah yang perlu dihapus
 */

delete from health_cleaning
where patient_id = '99' and full_name = 'April Little'; -- menghapus baris yang patient_idnya 99 dan full_namenya April Little
														-- statement where menggunakan and untuk menghindari penghapusan baris yang salah
delete from health_cleaning
where patient_id = '132' and full_name = 'Mr. Micheal Evans'; 

delete from health_cleaning
where patient_id = '137' and full_name = 'Monica Nielsen';

delete from health_cleaning
where patient_id = '335' and full_name = 'Marc Lopez';

delete from health_cleaning
where patient_id = '404' and full_name = 'Christine Watson';

delete from health_cleaning
where patient_id = '435' and full_name = 'Laura Gonzalez';

delete from health_cleaning
where patient_id = '475' and full_name = 'Leroy Thomas';

delete from health_cleaning
where patient_id = '484' and full_name = 'John Clark';

-- Cek ulang
select*
from health_cleaning
order by patient_id asc;

select max(patient_id) as id_terbaru, count(patient_id) as jumlah_pasien
from health_cleaning; -- id terbesar dan jumlah pasien sama

-- Memperbaiki format isi kolom
--- standarisasi kolom full_name
update health_cleaning
set full_name = initcap(trim(full_name)); -- menjadikan kapital huruf pertama setiap kata dan menghapus spasi berlebih

select full_name, position('Mr.' in full_name) as Mr, position('Ms.' in full_name) as Ms, position('Mrs.' in full_name) as Mrs, position ('Miss' in full_name) as miss
from health_cleaning; -- kolom bernilai 1 berarti full_name terdapat kata panggilan depan nama

select split_part('Mrs. Ashley Kim Dds', 'Mrs.', 1), split_part('Mrs. Ashley Kim Dds', 'Mrs.', 2), trim(split_part('Mrs. Ashley Kim Dds', 'Mrs.', 2));
--- menghapus kata panggilan
update health_cleaning
set full_name =
case 
	when position('Mr.' in full_name) = 1 then trim(split_part(full_name,'Mr.', 2))
	when position('Ms' in full_name) = 1 then trim(split_part(full_name,'Ms.', 2))
	when position('Mrs.' in full_name) = 1 then trim(split_part(full_name,'Mrs.', 2))
	when position('Miss' in full_name) = 1 then trim(split_part(full_name,'Miss', 2))
	else full_name
end;

--- standarisasi kolom gender
select distinct gender
from health_cleaning; -- banyak variasi female dan male yang perlu diseragamkan

update health_cleaning
set gender = initcap(gender); -- Kapital untuk awal kata

update health_cleaning
set gender = 
case 
	when gender = 'M' then 'Male'
	when gender = 'F' then 'Female'
	else gender
end;

-- standarisasi kolom date_of_birth
select date_of_birth from health_cleaning
order by date_of_birth;

UPDATE health_cleaning
SET date_of_birth =
    case 
	    -- jika format MM-DD-YY
	    when trim(date_of_birth) ~ '^[0-9]{2}-[0-9]{2}-[0-9]{2}$'
	    and pg_input_is_valid(
	    case 
	    	when substring(trim(date_of_birth), 7, 2):: integer <= 27 then '20' else '19'
	    end ||
             SUBSTRING(TRIM(date_of_birth), 7, 2) || '-' ||
             SUBSTRING(TRIM(date_of_birth), 1, 2) || '-' ||
             SUBSTRING(TRIM(date_of_birth), 4, 2),
             'date'
         )
	    then to_char(to_date(case when substring(trim(date_of_birth),7,2)::integer <= 27 then '20' else '19' end ||
        substring(trim(date_of_birth), 7,2) || '-' || 
        SUBSTRING(TRIM(date_of_birth), 1, 2) || '-' ||
        SUBSTRING(TRIM(date_of_birth), 4, 2),
        'YYYY-MM-DD'
        ), -- khusus format tahun YY perlu diperjelas abadnya karena bawaan Postgresql tahun 00-69 dihitung masuk abad 20 (69 dianggap tahun 2069)
        'YYYY-MM-DD'
        )
	    -- jika format DD-MM-YY
	    when trim(date_of_birth) ~ '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' 
	    and pg_input_is_valid(
	    case 
	    	when substring(trim(date_of_birth), 7, 2):: integer <= 27 then '20' else '19' -- jika tahun YY <= 27 dianggap lahir di abad 20
	    end ||
             SUBSTRING(TRIM(date_of_birth), 7, 2) || '-' ||
             SUBSTRING(TRIM(date_of_birth), 4, 2) || '-' ||
             SUBSTRING(TRIM(date_of_birth), 1, 2),
             'date'
         )
        then to_char(to_date(case when substring(trim(date_of_birth),7,2)::integer <= 27 then '20' else '19' end ||
        substring(trim(date_of_birth), 7,2) || '-' || 
        SUBSTRING(TRIM(date_of_birth), 4, 2) || '-' ||
        SUBSTRING(TRIM(date_of_birth), 1, 2),
        'YYYY-MM-DD'  -- khusus format tahun YY perlu diperjelas abadnya karena bawaan Postgresql tahun 00-69 dihitung masuk abad 20 (69 dianggap tahun 2069)
        ),
        'YYYY-MM-DD'
        )
        -- jika format DD-Mon-YYYY
	    when trim(date_of_birth) ~ '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$'
	    then to_char(to_date(trim(date_of_birth), 'DD-Mon-YYYY'), 'YYYY-MM-DD')
        -- jika format MM/DD/YYYY
        when TRIM(date_of_birth) ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        and pg_input_is_valid(
             SUBSTRING(TRIM(date_of_birth), 7, 2) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 1, 2) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 4, 2),
             'date'
         )
        THEN to_char(TO_DATE(TRIM(date_of_birth), 'MM/DD/YYYY'),'YYYY-MM-DD')
        -- jika format DD/MM/YYYY
        when TRIM(date_of_birth) ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        and pg_input_is_valid(
             SUBSTRING(TRIM(date_of_birth), 7, 2) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 4, 2) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 1, 2),
             'date'
         )
         THEN to_char(TO_DATE(TRIM(date_of_birth), 'DD/MM/YYYY'),'YYYY-MM-DD')
        -- jika format Month DD, YYYY
        when trim(date_of_birth) ~ '^[A-Za-z]+ [0-9]{2}, [0-9]{4}$'
        then to_char(to_date(trim(date_of_birth), 'Month DD, YYYY'),'YYYY-MM-DD')
        -- jika format YYYY-MM-DD
        when trim(date_of_birth) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
        and pg_input_is_valid(
             SUBSTRING(TRIM(date_of_birth), 1, 4) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 6, 2) || '/' ||
             SUBSTRING(TRIM(date_of_birth), 9, 2),
             'date'
         )
        then to_char(to_date(trim(date_of_birth), 'YYYY-MM-DD'),'YYYY-MM-DD')
        -- jika null tetap null
        else date_of_birth
    end;

select patient_id, full_name, date_of_birth
from health_cleaning
order by date_of_birth;

-- standarisasi kolom phone
select phone
from health_cleaning
group by phone
order by phone asc; -- data terdiri atas nomor telepon, N/A, dan unknown

update health_cleaning
set phone = 'N/A'
where phone = 'unknown'; -- menyeragamkan unknown menjadi N/A

update health_cleaning
set phone = translate(phone, '- .()','') -- replace tanda '-',' ', '.', '(', ')' menjadi kosong atau '' (dihapus)
where phone != 'N/A';

update health_cleaning
set phone = 
case
	when length(phone) > 10 and left(phone, 2) = '+1' then split_part(phone, '+1', 2) -- menghapus +1 (nomor domisili) dari phone sehingga menyisakan 10 karakter
	else phone
end;

-- perbaiki kolom email
select position('@' in email), email -- cek apakah penulisan email memiliki @ di dalamnya
from health_cleaning
order by position('@' in email) asc; -- terdapat penulisan email yang tidak valid

update health_cleaning
set email = replace(email, ' at ', '@') -- mengganti ' at ' menjadi @
where position('@' in email) = 0; -- syarat: karakter @ tidak ada dalam email

select split_part(email, '@', 2) as domain_email -- cek domain email
from health_cleaning
group by split_part(email, '@', 2);

/*
 * Terdapat domain email yang tidak valid, yaitu:
 * 1) gmial.com
 * 2) gmail,com 
 * yang perlu diperbaiki
 */
 
update health_cleaning
set email =
case
	when split_part(email, '@', 2) = 'gmial.com' then concat(split_part(email,'@',1),'@gmail.com')
	when split_part(email, '@', 2) = 'gmail,com' then concat(split_part(email,'@',1),'@gmail.com')
	else email 
end;

-- cek email kembali
select split_part(email, '@', 2) as domain_email -- cek domain email
from health_cleaning
group by split_part(email, '@', 2);



-- standarisasi kolom city
select city 
from health_cleaning
group by city
order by city; -- cek city

update health_cleaning
set city = initcap(trim(city)); -- menghapus spasi berlebih dan menyamakan besar kecil tulisan

-- standarisasi kolom state
select state 
from health_cleaning
group by state
order by state; -- nama negara bagian tidak seragam

update health_cleaning
set state =  -- mengubah singkatan state menjadi nama penuh
case 
	when state in ('AK') then 'Alaska'
	when state in ('AL') then 'Alabama'
	when state in ('AR') then 'Arkansas'
	when state in ('AZ') then 'Arizona'
	when state in ('CA') then 'California'
	when state in ('CO') then 'Colorado'
	when state in ('CT') then 'Connecticut'
	when state in ('DC') then 'District of Columbia'
	when state in ('DE') then 'Delaware'
	when state in ('FL') then 'Florida'
	when state in ('FM') then 'Federasi Mikronesia'
	when state in ('GA') then 'Georgia'
	when state in ('GU') then 'Guam'
	when state in ('HI') then 'Hawaii'
	when state in ('IA') then 'Iowa'
	when state in ('ID') then 'Idaho'
	when state in ('IL') then 'Illinois'
	when state in ('IN') then 'Indiana'
	when state in ('KS') then 'Kansas'
	when state in ('KY') then 'Kentucky'
	when state in ('LA') then 'Louisiana'
	when state in ('MA') then 'Massachusetts'
	when state in ('MD') then 'Maryland'
	when state in ('ME') then 'Maine'
	when state in ('MH') then 'Kepulauan Marshall'
	when state in ('MI') then 'Michigan'
	when state in ('MN') then 'Minnesota'
	when state in ('MO') then 'Missouri'
	when state in ('MP') then 'Kepulauan Mariana Utara'
	when state in ('MS') then 'Mississippi'
	when state in ('MT') then 'Montana'
	when state in ('NC') then 'North Carolina'
	when state in ('ND') then 'North Dakota'
	when state in ('NE') then 'Nebraska'
	when state in ('NH') then 'New Hampshire'
	when state in ('NJ') then 'New Jersey'
	when state in ('NM') then 'New Mexico'
	when state in ('NV') then 'Nevada'
	when state in ('NY') then 'New York'
	when state in ('OH') then 'Ohio'
	when state in ('OK') then 'Oklahoma'
	when state in ('OR') then 'Oregon'
	when state in ('PA') then 'Pennsylvania'
	when state in ('PR') then 'Puerto Riko'
	when state in ('PW') then 'Palau'
	when state in ('RI') then 'Rhode Island'
	when state in ('SC') then 'South Carolina'
	when state in ('SD') then 'South Dakota'
	when state in ('TN') then 'Tennessee'
	when state in ('TX') then 'Texas'
	when state in ('UT') then 'Utah'
	when state in ('VA') then 'Virginia'
	when state in ('VI') then 'Virgin Islands'
	when state in ('VT') then 'Vermont'
	when state in ('WA') then 'Washington'
	when state in ('WI') then 'Wisconsin'
	when state in ('WV') then 'West Virginia'
	when state in ('WY') then 'Wyoming'
	else state
end;

-- standarisasi zip_code
select distinct zip_code
from health_cleaning
order by zip_code; -- terdapat zip_code yang lebih dari 5 angka, harus dibetulkan

update health_cleaning
set zip_code = split_part(zip_code,'-',1)
where length(trim(zip_code)) > 5; -- syarat ubah adalah yang zip_codenya memiliki lebih dari 5 karakter

-- standarisasi insurance_provider
select insurance_provider
from health_cleaning
group by insurance_provider 
order by insurance_provider;

update health_cleaning
set insurance_provider = initcap(insurance_provider); -- menyeragamkan penulisan kapital di awal kata

update health_cleaning
set insurance_provider = 
case -- menyeragamkan nama asuransi
	when insurance_provider in ('Aetna', 'Aetna Inc.', 'Aetnaa') then 'Aetna'
	when insurance_provider in ('Blue-Cross', 'Blue Cross', 'Bluecross') then 'Blue Cross'
	when insurance_provider in ('Cigna', 'Cigna Health') then 'Cigna Health'
	when insurance_provider in ('Medi-Care', 'Medicare') then 'Medicare'
	when insurance_provider in ('Self-Pay', 'Self Pay') then 'Self Pay'
	when insurance_provider in ('Uhc', 'United Health', 'Unitedhealth') then 'Unitedhealthcare'
	else insurance_provider
end;

-- standarisasi kolom registration_date
select distinct registration_date
from health_cleaning
order by registration_date;

UPDATE health_cleaning
SET registration_date =
    case -- karena registration_date memiliki rentang tanggal yang tidak jauh seperti date_of_birth, maka querynya bisa lebih singkat
	    -- jika format MM-DD-YY
	    when trim(registration_date) ~ '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' 
	    and pg_input_is_valid(
             SUBSTRING(TRIM(registration_date), 7, 2) || '-' ||
             SUBSTRING(TRIM(registration_date), 1, 2) || '-' ||
             SUBSTRING(TRIM(registration_date), 4, 2),
             'date'
         )
		then to_char(to_date(trim(registration_date), 'MM-DD-YY'),'YYYY-MM-DD')
		-- jika format MM/DD/YY
		when trim(registration_date) ~  '^[0-9]{2}/[0-9]{2}/[0-9]{2}$'
		and pg_input_is_valid(
			substring(trim(registration_date), 7,2) || '-' ||
			substring(trim(registration_date), 1,2) || '-' ||
			substring(trim(registration_date), 4,2)
			,'date'
		)
		then to_char(to_date(trim(registration_date), 'MM/DD/YY'), 'YYYY-MM-DD')
		-- jika format MM/DD/YYYY
		when trim(registration_date) ~  '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
		and pg_input_is_valid(
			substring(trim(registration_date), 7,4) || '-' ||
			substring(trim(registration_date), 1,2) || '-' ||
			substring(trim(registration_date), 4,2)
			,'date'
		)
		then to_char(to_date(trim(registration_date), 'MM/DD/YYYY'), 'YYYY-MM-DD')
		-- jika format DD-Mon-YYYY
		when trim(registration_date) ~  '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$'
		and pg_input_is_valid(
			substring(trim(registration_date), 8,4) || '-' ||
			substring(trim(registration_date), 4,3) || '-' ||
			substring(trim(registration_date), 1,2)
			, 'date'
		)
		then to_char(to_date(trim(registration_date), 'DD-Mon-YYYY'), 'YYYY-MM-DD')
		-- jika format Month DD, YYYY
		when trim(registration_date) ~  '^[A-Za-z]+ [0-9]{2}, [0-9]{4}$'
		and pg_input_is_valid(
			split_part(trim(registration_date), ' ',1) || '-' ||
			substring(split_part(trim(registration_date), ' ',2), 1, 2) || '-' ||
			split_part(trim(registration_date), ' ',3)
			, 'date'
		)
		then to_char(to_date(trim(registration_date), 'Month DD, YYYY'), 'YYYY-MM-DD')
		else registration_date
	end;


-- Alter table cleaning

-- tambah constraint primary key ke kolom patient_id
ALTER TABLE health_cleaning
ADD CONSTRAINT pk_patientid 
primary key(patient_id);

-- ubah jenis data kolom date_of_birth dan registration_date ke date
ALTER TABLE health_cleaning 
ALTER COLUMN date_of_birth TYPE DATE 
using to_date(date_of_birth, 'YYYY-MM-DD');

ALTER TABLE health_cleaning 
ALTER COLUMN registration_date TYPE DATE 
using to_date(registration_date, 'YYYY-MM-DD');

-- tambah constrant not null untuk kolom full_name
ALTER TABLE employee
ADD CONSTRAINT notnull_name
not null (full_name);

--drop table health_cleaning;

-- Selesai
/*
 * selesai proses cleaning data ini. Walaupun namanya 'Healthcare Data Cleaning Series (Easy)', bagi saya ini tidak easy hehe.
 * Apabila terdapat proses cleaning yang luput dari query yang saya buat. Saya terbuka untuk menerima masukkan dan saran. Terima kasih 
 */
