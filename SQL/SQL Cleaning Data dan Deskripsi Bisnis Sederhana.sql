/*
 * Tentang Data:
 * Data merupakan data sintetis terkait ecommerce yang bersumber dari https://www.kaggle.com/datasets/zkyfauzi/indonesia-ecommerce-sales
 */

--Membuat Tabel ecommerce_sales
create table ecommerce_sales (
	order_id varchar(15) primary key,
	total_qty decimal(5,1),
	total_weight_gr int,
	total_returned_qty int,
	Total_Diskon int,
	product_categories varchar(250),
	num_product_categories int,
	Status_Pesanan varchar(100),
	Alasan_Pembatalan varchar(200),
	Opsi_Pengiriman varchar(100),
	Metode_Pembayaran varchar(50),
	Kota_Kabupaten varchar(50),
	Provinsi varchar(50),
	Ongkos_Kirim_Dibayar_oleh_Pembeli int,
	Estimasi_Potongan_Biaya_Pengiriman int,
	Total_Pembayaran int,
	Perkiraan_Ongkos_Kirim int,
	Waktu_Pesanan_Dibuat timestamp,
	order_date date
);


copy ecommerce_sales
FROM 'D:\Downloads\Dataset Kaggle\indonesia_ecommerce_sales_challenging.csv' DELIMITER ';' CSV header;
-- eror akibat data tidak valid, yaitu 2024-13-40 (akan diperbaiki kemudian)


-- Alter kolom order_date dari date menjadi varchar agar semua data bisa diinput ke tabel tanpa eror
alter table ecommerce_sales
alter column order_date type varchar(15);

-- input ulang dataset csv ke tabel
copy ecommerce_sales
FROM 'D:\Downloads\Dataset Kaggle\indonesia_ecommerce_sales_challenging.csv' DELIMITER ';' CSV header;

-- Melihat Tabel untuk 10 baris pertama
select *
from ecommerce_sales
limit 10;

-- Perbaiki data order_date
/*
 date_order terdapat tanggal invalid yang perlu diganti.
 Catatan: data kaggle sebelum didownload memiliki format tanggal yyyy-mm-dd dan dd-mm-yyyy 
 yang otomatis semuanya berubah format menjadi dd-mm-yyyy saat saya buka di microsoft excel.
 */
ALTER TABLE ecommerce_sales
ADD COLUMN order_date_valid date; -- Buat tabel baru bernama order_date_valid tipe date

-- mengubah data order_date bertipe varchar ke date dan masukkan ke kolom order_date_valid
update ecommerce_sales
set order_date_valid =
    case -- jika tanggal tidak valid maka bernilai NULL
        WHEN pg_input_is_valid(NULLIF(order_date, ''), 'date')
        THEN NULLIF(order_date, '')::DATE
        ELSE NULL
    end
where order_date is not null; 

-- Mengecek nilai yang tidak valid
select order_date, order_date_valid
from ecommerce_sales
where order_date_valid is null; -- tanggal tidak valid sudah menjadi null

-- Cek NULL
select 
	count(*) as total_baris,
	sum(case when total_qty is null then 1 else 0 end) as missing_Total_qty,
	sum(case when total_weight_gr is null then 1 else 0 end) as missing_total_weight_gr,
	sum(case when total_returned_qty is null then 1 else 0 end) as missing_total_returned_qty,
	sum(case when total_diskon is null then 1 else 0 end) as missing_total_diskon,
	sum(case when product_categories is null then 1 else 0 end) as missing_product_categories,
	sum(case when num_product_categories is null then 1 else 0 end) as missing_num_product_categories,
	sum(case when status_pesanan is null then 1 else 0 end) as missing_status_pesanan,
	sum(case when alasan_pembatalan is null then 1 else 0 end) as missing_alasan_pembatalan,
	sum(case when opsi_pengiriman is null then 1 else 0 end) as missing_opsi_pengiriman,
	sum(case when metode_pembayaran is null then 1 else 0 end) as missing_metode_pembayaran,
	sum(case when kota_kabupaten is null then 1 else 0 end) as missing_kota_kabupaten,
	sum(case when provinsi is null then 1 else 0 end) as missing_provinsi,
	sum(case when ongkos_kirim_dibayar_oleh_pembeli is null then 1 else 0 end) as missing_ongkos_dibayar_pembeli,
	sum(case when estimasi_potongan_biaya_pengiriman is null then 1 else 0 end) as missing_est_potongan_ongkos,
	sum(case when total_pembayaran is null then 1 else 0 end) as missing_total_pembayaran,
	sum(case when perkiraan_ongkos_kirim is null then 1 else 0 end) as missing_perkiraan_ongkir,
	sum(case when waktu_pesanan_dibuat is null then 1 else 0 end) as missing_waktu_pesanan_dibuat,
	sum(case when order_date is null then 1 else 0 end) as missing_order_date
from ecommerce_sales;

/*
 * Hasilnya terdapat 3 kolom yang memiliki missing value, yaitu:
 * kolom total_qty missing value 283
 * kolom metode_pembayaran missing value 283
 * kolom order_date missing value 188
 */

-- Membersihkan Null dari total_qty
select 
	*
from ecommerce_sales
where total_qty is null; -- setelah cek ulang tidak ada lagi data null

DELETE FROM ecommerce_sales
WHERE total_qty is null;

-- Membersihkan Null dari metode_pembayaran
select distinct 
	metode_pembayaran
from ecommerce_sales; -- setelah cek ulang data null berubah menjadi Tidak diketahui

update ecommerce_sales
set metode_pembayaran = 'Tidak diketahui'
where metode_pembayaran is null;

-- Menyeragamkan penulisan metode pembayaran
update ecommerce_sales
set metode_pembayaran = UPPER(metode_pembayaran); -- membuat semua menjadi kapital

update ecommerce_sales
set metode_pembayaran =
case
	when metode_pembayaran = 'ONLINEPAYMENT' then 'ONLINE PAYMENT'
	when metode_pembayaran = 'SALDO SHOPEEPAY' then 'SHOPEEPAY'
	when metode_pembayaran = 'COD' then 'CASH ON DELIVERY'
	when metode_pembayaran = 'COD (BAYAR DI TEMPAT)' then 'CASH ON DELIVERY'
	when metode_pembayaran = 'SPAY LATER' then 'SPAYLATER'
	when metode_pembayaran = 'CICILAN KARTU KREDIT' then 'KARTU KREDIT/DEBIT'
	when metode_pembayaran = 'ALFAMART/ALFAMIDI/DAN+DAN' then 'ALFAMART/ALFAMIDI'
	when metode_pembayaran = 'INDOMARET/I.SAKU' then 'INDOMARET'
	when metode_pembayaran = 'BCA ONEKLIK' then 'BCA'
	when metode_pembayaran = 'SEABANK BAYAR INSTAN' then 'SEABANK'
	else metode_pembayaran
end; -- ubah beberapa nama agar seragam dan lebih rapi

-- mengecek kembali metode pembayaran
select distinct metode_pembayaran
from ecommerce_sales; -- metode_pembayaran lebih rapi dan konsisten

-- membersihkan null dari order_date
select waktu_pesanan_dibuat, order_date
from ecommerce_sales; --Diketahui bahwa tanggal order_date adalah sama seperti tanggal di waktu_pesanan_dibuat

update ecommerce_sales
set order_date = date(waktu_pesanan_dibuat) -- mengganti tanggal sesuai tanggal di waktu_pesanan_dibuat jika order_date null
where order_date is null;

-- mengecek total_pembayaran bernilai 0 rupiah
select *
from ecommerce_sales
where total_pembayaran = 0
order by total_diskon desc;

select distinct status_pesanan
from ecommerce_sales
where total_pembayaran = 0;
/*
 * memang ada yang memiliki diskon tetapi semuanya berstatus batal yang artinya memang logis tidak ada pembayaran.
 * data yang menarik adalah total_pembayaran 0 rupiah tetapi kolom status_pesanan memiliki status selesai, nah inilah anomali yang perlu dihilangkan
 */

-- menghapus baris dengan total_pembayaran 0 yang status_pesanannya selesai
delete from ecommerce_sales
where total_pembayaran = 0 and status_pesanan = 'Selesai';

-- Menjawab pertanyaan bisnis sederhana

-- 1. Statisik deskriptif dari total_pembayaran berapa?
SELECT 
 	min(total_pembayaran) as minimum,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_pembayaran) AS q1,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_pembayaran) AS median,
    round(AVG(total_pembayaran),3) as ratarata,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_pembayaran) AS q3,
    max(total_pembayaran) as maksimum
FROM ecommerce_sales;

-- 2. Apakah terdapat transaksi outlier?

with kuartil as(
	select 
		percentile_cont(0.25) within group (order by total_pembayaran) as q1,
		PERCENTILE_CONT(0.75) within group (order by total_pembayaran) as q3
	from ecommerce_sales
	where status_pesanan != 'Batal'
),
limits as (
	select q1,q3, q3 - q1 as iqr,
		q1 - 1.5*(q3 - q1) as batas_bawah,
		q3 + 1.5*(q3 - q1) as batas_atas
	from kuartil
)
select
	e.*,
	l.q1,
	l.q3,
	l.iqr,
	l.batas_bawah,
	l.batas_atas
from ecommerce_sales as e
cross join limits as l
where (e.total_pembayaran < l.batas_bawah or e.total_pembayaran > l.batas_atas)
order by e.total_pembayaran desc;

/*
 * Jawabannya ada. total_pembayaran tertinggi sekaligus outlier berada pada nilai Rp3.076.000,00 dan terkecil Rp85.485
 */


-- 3. Jika ada outlier, product_categories apa yang menyubangkan paling banyak outlier dan efeknya pada total_pembayaran?
with kuartil as(
	select 
		percentile_cont(0.25) within group (order by total_pembayaran) as q1,
		PERCENTILE_CONT(0.75) within group (order by total_pembayaran) as q3
	from ecommerce_sales
),
limits as (
	select q1,q3, q3 - q1 as iqr,
		q1 - 1.5*(q3 - q1) as batas_bawah,
		q3 + 1.5*(q3 - q1) as batas_atas
	from kuartil
)
select
	e.product_categories,
	count(e.*) as total_outlier,
	sum(e.total_pembayaran) as total_pembayaran_outlier,
	sum(e.total_qty) as total_barang_outlier
from ecommerce_sales as e
cross join limits as l
where e.total_pembayaran < l.batas_bawah or e.total_pembayaran > l.batas_atas
group by e.product_categories
order by total_pembayaran_outlier desc;

/*
 * hasil tabel menunjukkan total outlier untuk kategori Seal/Baut/Roof berjumlah 362 dengan total nilai transaksi 238 juta.
 * Diikuti Nampan/Tray dan Lunch Box/Rantang masing-masing 66 juta dan 32 juta. 
 * Berdasarkan total barang terjual diketahui bahwa 3 kategori ini bisa jadi berasal dari pembeli grosir berarti data itu riil.
 * Menarik adalah urutan terbawah dari tabel ini masih berada di atas batas atas karena batas_bawah sendiri bernilai minus.
 */

-- 4. Metode pembayaran apa yang paling banyak digunakan konsumen?
select metode_pembayaran, count(*) as jumlah_pembayaran
from ecommerce_sales
where status_pesanan != 'Batal'
group by metode_pembayaran
order by jumlah_pembayaran desc; -- konsumen paling banyak menggunakan metode COD

-- 5. Berapa banyak barang yang diretur dan dari kategori apa saja?
select sum(total_returned_qty) as jumlah_barang_retur
from ecommerce_sales; -- total barang return berjumlah 210

select product_categories, sum(total_returned_qty) as jumlah_barang_retur
from ecommerce_sales
group by product_categories
order by jumlah_barang_retur desc; -- toko perlu melakukan quality control lebih untuk kategori-kategori penyumbang retur terbanyak

-- 6. Berapa banyak pengiriman yang dibatalkan dan dari mana sumber pembatalannya?
select split_part(alasan_pembatalan, '.',1) as kategori_pembatalan, split_part(alasan_pembatalan, '.',2) as alasan, count(status_pesanan) as jumlah_pesanan_batal
from ecommerce_sales
where status_pesanan = 'Batal'
group by kategori_pembatalan, alasan
order by jumlah_pesanan_batal desc;
/*
 * hasil yang perlu diperhatikan ada pada kategori dibatalkan oleh sistem karena memiliki alasan yang krusial terhadap bisnis, yaitu:
 * 1. pengiriman gagal
 * 2. penjual gagal mengirimkan pesanan tepat waktu
 * 3. penjual tidak mengatur pengiriman tepat waktu
 * 4. paket hilang di perjalanan
 * Perlu dilakuka evaluasi terhadap kurir dan penjual agar tidak terjadi hal serupa dan pembeli tidak kabur karena alasan negatif
 */

-- 7. 20 Kota/Kabupaten dengan total pembayaran tertinggi?
select kota_kabupaten, sum(total_pembayaran) as total_pembayaran, count(*) as jumlah_pembeli
from ecommerce_sales
group by kota_kabupaten
order by total_pembayaran desc
limit 20;

--drop table ecommerce_sales;


-- sekian, terima kasih