use master
go

create database db_web_ban_hang_mafia
go

use db_web_ban_hang_mafia
go


CREATE TABLE PhanQuyen
(
    MaQuyen CHAR(10) NOT NULL,
    VaiTro NVARCHAR(10) CHECK (VaiTro IN (N'Nhân viên', N'Khách hàng')),
    CONSTRAINT PK_PhanQuyen PRIMARY KEY(MaQuyen)
);
-- Table người dùng có thể vừa là nhân viên, vừa là khách hàng
CREATE TABLE NguoiDung
(
    MaNguoiDung INT IDENTITY(1,1), -- Thuộc tính tự động tăng
    HoTen NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(100) NULL,
    SoDienThoai VARCHAR(10) CHECK(LEN(SoDienThoai) = 10 AND ISNUMERIC(SoDienThoai) = 1) NOT NULL UNIQUE, -- Kiểu VARCHAR thay vì CHAR
    MatKhau CHAR(50) NOT NULL,
    MaQuyen CHAR(10) NOT NULL,
    CONSTRAINT PK_NguoiDung PRIMARY KEY(MaNguoiDung),
    CONSTRAINT FK_NguoiDung_PhanQuyen FOREIGN KEY(MaQuyen) REFERENCES PhanQuyen(MaQuyen)
);

CREATE TABLE LoaiSanPham
(
    MaLoaiSP CHAR(10) NOT NULL,
    TenLoaiSP NVARCHAR(100),
    CONSTRAINT PK_LoaiSanPham PRIMARY KEY(MaLoaiSP)
);


CREATE TABLE GiamGia
(
    MaGG CHAR(10) NOT NULL,
    TenGG NVARCHAR(100) NOT NULL,
    NgayBD DATE NOT NULL,
    NgayKT DATE NOT NULL, -- Kiểm tra ngày kết thúc lớn hơn ngày bắt đầu
    PhanTramGiam DECIMAL(5, 2) CHECK (PhanTramGiam > 0 AND PhanTramGiam <= 100) NOT NULL,
    CONSTRAINT PK_GiamGia PRIMARY KEY(MaGG),
	CONSTRAINT CHECK_NgayKT CHECK (NgayKT >= NgayBD)
);

CREATE TABLE SanPham
(
    MaSanPham CHAR(10) NOT NULL,
    MaLoaiSP CHAR(10),
    TenSanPham NVARCHAR(100) NOT NULL,
    Gia DECIMAL(10, 2) CHECK(Gia > 0) NOT NULL,
    MoTa NVARCHAR(255) NULL,
    HinhAnh NVARCHAR(50) NULL,
    TrangThai BIT DEFAULT 1, -- 1 là đang bán, còn 0 là ngừng bán
    SoLuong INT CHECK(SoLuong >= 0) NOT NULL, -- Kiểm tra tồn kho
    CONSTRAINT PK_SanPham PRIMARY KEY(MaSanPham),
	CONSTRAINT FK_SanPham_LoaiSP FOREIGN KEY(MaLoaiSP) REFERENCES LoaiSanPham(MaLoaiSP)
);

CREATE TABLE GioHang
(
    MaGioHang CHAR(10),
    MaNguoiDung INT NOT NULL,
    NgayTao DATETIME DEFAULT GETDATE(),
	TongTien DECIMAL(10, 2),
    TrangThai NVARCHAR(20) CHECK(TrangThai IN (N'Đang xử lý', N'Đã thanh toán', N'Đã hủy')) NOT NULL,
	MaGG CHAR(10),
    CONSTRAINT PK_GioHang PRIMARY KEY(MaGioHang),
    CONSTRAINT FK_GioHang_NguoiDung FOREIGN KEY(MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
	CONSTRAINT FK_GioHang_GiamGia FOREIGN KEY(MaGG) REFERENCES GiamGia(MaGG)
);

CREATE TABLE ChiTietGioHang
(
    MaGioHang CHAR(10),
    MaSanPham CHAR(10) NOT NULL,
    SoLuong INT CHECK(SoLuong >= 1) NOT NULL,
	ThanhTien DECIMAL(10, 2),
    CONSTRAINT PK_ChiTietGioHang PRIMARY KEY( MaSanPham,MaGioHang),
	CONSTRAINT FK_ChiTietGioHang_GioHang FOREIGN KEY(MaGioHang) REFERENCES GioHang(MaGioHang) ON DELETE CASCADE,
    CONSTRAINT FK_ChiTietGioHang_SanPham FOREIGN KEY(MaSanPham) REFERENCES SanPham(MaSanPham)
)

CREATE TABLE HoaDonBanHang
(
    MaHoaDon CHAR(10) NOT NULL,
    MaKH INT,
    MaNV INT,
    NgayLap DATE NOT NULL, -- Ngày lập hóa đơn không thể null
    TongTien DECIMAL(10, 2) NOT NULL,
    MaGG CHAR(10),
    TrangThai NVARCHAR(50) CHECK(TrangThai IN (N'Chờ xác nhận', N'Đang xử lý', N'Đang giao', N'Đã hoàn thành',N'Đã từ chối')) NOT NULL,
    PhuongThucThanhToan NVARCHAR(100) NOT NULL,
	DiaChiGiaoHang NVARCHAR(100), 
	HoTenKH NVARCHAR(100), 
	SdtGiaoHang NVARCHAR(100),
    CONSTRAINT PK_HoaDonBanHang PRIMARY KEY(MaHoaDon),
    CONSTRAINT FK_HoaDonBanHang_KhachHang FOREIGN KEY(MaKH) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_HoaDonBanHang_NhanVien FOREIGN KEY(MaNV) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_HoaDonBanHang_GiamGia FOREIGN KEY(MaGG) REFERENCES GiamGia(MaGG) ON DELETE SET NULL
);

CREATE TABLE ChiTietHoaDonBanHang
(
    MaSanPham CHAR(10) NOT NULL,
    MaHoaDon CHAR(10) NOT NULL,
    SoLuong INT CHECK(SoLuong >= 1) NOT NULL,
    Gia DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_ChiTietHoaDonBanHang PRIMARY KEY(MaSanPham, MaHoaDon),
	CONSTRAINT FK_ChiTietHoaDonBanHang_SanPham FOREIGN KEY(MaSanPham) REFERENCES SanPham(MaSanPham) ON DELETE CASCADE,
    CONSTRAINT FK_ChiTietHoaDonBanHang_HoaDonBanHang FOREIGN KEY(MaHoaDon) REFERENCES HoaDonBanHang(MaHoaDon) ON DELETE CASCADE
);

INSERT INTO PhanQuyen (MaQuyen, VaiTro) VALUES ('NV', N'Nhân viên');
INSERT INTO PhanQuyen (MaQuyen, VaiTro) VALUES ('KH', N'Khách hàng');

INSERT INTO NguoiDung (HoTen, DiaChi, SoDienThoai, MatKhau, MaQuyen) 
VALUES (N'Nguyễn Văn A', N'123 Đường A', '0123456789', 'password123', 'NV');

INSERT INTO NguoiDung (HoTen, DiaChi, SoDienThoai, MatKhau, MaQuyen) 
VALUES (N'Lê Thị B', N'456 Đường B', '0987654321', 'password456', 'KH');

INSERT INTO NguoiDung (HoTen, DiaChi, SoDienThoai, MatKhau, MaQuyen) 
VALUES (N'Phạm Văn C', N'789 Đường C', '0123451234', 'password789', 'KH');

INSERT INTO LoaiSanPham (MaLoaiSP, TenLoaiSP) VALUES
('LSP01', N'Thức Uống'),
('LSP02', N'Thực Phẩm Tươi'),
('LSP03', N'Thực Phẩm Khô'),
('LSP04', N'Gia Vị & Đồ Hộp'),
('LSP05', N'Bánh kẹo');

INSERT INTO SanPham VALUES ('SP001', 'LSP01', N'Mineral Water', 8000, N'Nước khoáng', 'mineral_water.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP002', 'LSP02', N'Eggs', 30000, N'Trứng', 'eggs.jpg', 1, 60);
INSERT INTO SanPham VALUES ('SP003', 'LSP03', N'Spaghetti', 28000, N'Mì ống spaghetti', 'spaghetti.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP004', 'LSP04', N'French Fries', 25000, N'Khoai tây chiên', 'french_fries.jpg', 1, 45);
INSERT INTO SanPham VALUES ('SP005', 'LSP05', N'Chocolate', 35000, N'Sô cô la', 'chocolate.jpg', 1, 55);
INSERT INTO SanPham VALUES ('SP006', 'LSP02', N'Green Tea', 15000, N'Trà xanh', 'green_tea.jpg', 1, 70);
INSERT INTO SanPham VALUES ('SP007', 'LSP01', N'Milk', 27000, N'Sữa', 'milk.jpg', 1, 60);
INSERT INTO SanPham VALUES ('SP008', 'LSP02', N'Ground Beef', 85000, N'Thịt bò xay', 'ground_beef.jpg', 1, 35);
INSERT INTO SanPham VALUES ('SP009', 'LSP02', N'Frozen Vegetables', 30000, N'Rau củ đông lạnh', 'frozen_vegetables.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP010', 'LSP03', N'Pancakes', 20000, N'Bánh kếp', 'pancakes.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP011', 'LSP03', N'Burgers', 35000, N'Bánh mì kẹp thịt', 'burgers.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP012', 'LSP03', N'Cake', 30000, N'Bánh kem', 'cake.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP013', 'LSP03', N'Cookies', 25000, N'Bánh quy', 'cookies.jpg', 1, 45);
INSERT INTO SanPham VALUES ('SP014', 'LSP03', N'Escalope', 75000, N'Thịt tẩm bột chiên', 'escalope.jpg', 1, 20);
INSERT INTO SanPham VALUES ('SP015', 'LSP04', N'Low Fat Yogurt', 18000, N'Sữa chua ít béo', 'low_fat_yogurt.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP016', 'LSP02', N'Shrimp', 95000, N'Tôm', 'shrimp.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP017', 'LSP02', N'Tomatoes', 18000, N'Cà chua', 'tomatoes.jpg', 1, 60);
INSERT INTO SanPham VALUES ('SP018', 'LSP04', N'Olive Oil', 110000, N'Dầu ô liu', 'olive_oil.jpg', 1, 25);
INSERT INTO SanPham VALUES ('SP019', 'LSP01', N'Frozen Smoothie', 25000, N'Sinh tố', 'frozen_smoothie.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP020', 'LSP02', N'Turkey', 95000, N'Thịt gà tây', 'turkey.jpg', 1, 20);
INSERT INTO SanPham VALUES ('SP021', 'LSP02', N'Chicken', 80000, N'Thịt gà', 'chicken.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP022', 'LSP03', N'Whole Wheat Rice', 25000, N'Gạo lứt', 'whole_wheat_rice.jpg', 1, 35);
INSERT INTO SanPham VALUES ('SP023', 'LSP03', N'Grated Cheese', 40000, N'Phô mai bào', 'grated_cheese.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP024', 'LSP04', N'Cooking Oil', 45000, N'Dầu ăn', 'cooking_oil.jpg', 1, 45);
INSERT INTO SanPham VALUES ('SP025', 'LSP02', N'Soup', 20000, N'Súp', 'soup.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP026', 'LSP03', N'Herb & Pepper', 20000, N'Gia vị và tiêu', 'herb_pepper.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP027', 'LSP03', N'Honey', 60000, N'Mật ong', 'honey.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP028', 'LSP01', N'Champagne', 320000, N'Sâm panh', 'champagne.jpg', 1, 15);
INSERT INTO SanPham VALUES ('SP029', 'LSP02', N'Fresh Bread', 15000, N'Bánh mì tươi', 'fresh_bread.jpg', 1, 60);
INSERT INTO SanPham VALUES ('SP030', 'LSP02', N'Salmon', 125000, N'Cá hồi', 'salmon.jpg', 1, 25);
INSERT INTO SanPham VALUES ('SP031', 'LSP05', N'Brownies', 25000, N'Bánh socola brownies', 'brownies.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP032', 'LSP02', N'Avocado', 30000, N'Bơ', 'avocado.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP033', 'LSP03', N'Hot Dogs', 28000, N'Xúc xích kẹp bánh mì', 'hot_dogs.jpg', 1, 35);
INSERT INTO SanPham VALUES ('SP034', 'LSP02', N'Cottage Cheese', 32000, N'Phô mai tươi', 'cottage_cheese.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP035', 'LSP01', N'Tomato Juice', 22000, N'Nước ép cà chua', 'tomato_juice.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP036', 'LSP02', N'Butter', 40000, N'Bơ nấu ăn', 'butter.jpg', 1, 40);
INSERT INTO SanPham VALUES ('LSP02', 'LSP03', N'Whole Wheat Pasta', 30000, N'Mì ống nguyên cám', 'whole_wheat_pasta.jpg', 1, 35);
INSERT INTO SanPham VALUES ('SP038', 'LSP01', N'Red Wine', 250000, N'Rượu vang đỏ', 'red_wine.jpg', 1, 15);
INSERT INTO SanPham VALUES ('SP039', 'LSP05', N'Yogurt Cake', 28000, N'Bánh sữa chua', 'yogurt_cake.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP040', 'LSP04', N'Light Mayo', 22000, N'Sốt mayonnaise ít béo', 'light_mayo.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP041', 'LSP05', N'Energy Bar', 18000, N'Thanh năng lượng', 'energy_bar.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP042', 'LSP02', N'Ham', 60000, N'Giăm bông', 'ham.jpg', 1, 30);
INSERT INTO SanPham VALUES ('SP043', 'LSP01', N'Energy Drink', 25000, N'Nước tăng lực', 'energy_drink.jpg', 1, 45);
INSERT INTO SanPham VALUES ('SP044', 'LSP03', N'Pepper', 20000, N'Tiêu', 'pepper.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP045', 'LSP02', N'Vegetables Mix', 30000, N'Rau trộn', 'vegetables_mix.jpg', 1, 35);
INSERT INTO SanPham VALUES ('SP046', 'LSP03', N'Cereals', 40000, N'Ngũ cốc', 'cereals.jpg', 1, 40);
INSERT INTO SanPham VALUES ('SP047', 'LSP05', N'Muffins', 25000, N'Bánh muffin', 'muffins.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP048', 'LSP02', N'Oil', 45000, N'Dầu ăn', 'oil.jpg', 1, 50);
INSERT INTO SanPham VALUES ('SP049', 'LSP01', N'French Wine', 280000, N'Rượu vang Pháp', 'french_wine.jpg', 1, 20);
INSERT INTO SanPham VALUES ('SP050', 'LSP02', N'Fresh Tuna', 120000, N'Cá ngừ tươi', 'fresh_tuna.jpg', 1, 25);


INSERT INTO GiamGia (MaGG, TenGG, NgayBD, NgayKT, PhanTramGiam)
VALUES 
('GG001', N'Giảm giá mùa hè', '2024-06-01', '2024-06-30', 10.00),
('GG002', N'Giảm giá năm mới', '2024-01-01', '2024-01-15', 20.00),
('GG003', N'Giảm giá cuối năm', '2024-12-01', '2026-12-31', 15.00);


SELECT * FROM SanPham

SELECT * FROM GioHang

SELECT * FROM ChiTietGioHang