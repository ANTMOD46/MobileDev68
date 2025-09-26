# 🛍️ Simple Product Manager App

**แอปพลิเคชันจัดการสินค้าอย่างง่ายด้วย Flutter และ PocketBase**

แอปพลิเคชันนี้ถูกออกแบบมาเพื่อเป็นตัวอย่างการจัดการข้อมูลสินค้า (เพิ่ม, แก้ไข, ลบ, ดูข้อมูล) โดยใช้ **Flutter** สำหรับการพัฒนา Mobile App และใช้ **PocketBase** เป็น Backend-as-a-Service (BaaS) แบบเรียลไทม์ที่รวดเร็วและใช้งานง่าย

---

### ✨ ฟีเจอร์หลัก

* **สร้าง, แก้ไข, ลบ สินค้า**: จัดการข้อมูลสินค้าได้อย่างสมบูรณ์ (CRUD)
* **การอัปเดตแบบเรียลไทม์**: การเปลี่ยนแปลงข้อมูลจะอัปเดตบนหน้าจอทันทีโดยไม่ต้องรีเฟรช
* **การเลื่อนเพื่อโหลดข้อมูลเพิ่มเติม**: ดึงข้อมูลสินค้าจำนวนมากได้อย่างราบรื่น
* **การจัดการรูปภาพ**: อัปโหลดและแสดงรูปภาพสินค้าได้ง่าย
* **UI ที่เป็นมิตรกับผู้ใช้**: ออกแบบด้วยดีไซน์ที่สวยงามและใช้งานง่าย

---

### 💻 เทคโนโลยีที่ใช้

* **Flutter**: Framework UI สำหรับการสร้างแอปพลิเคชันข้ามแพลตฟอร์ม
* **PocketBase**: Backend-as-a-Service ที่มีฐานข้อมูลแบบเรียลไทม์, ระบบจัดการไฟล์, และ REST API ในตัว
* **Google Fonts**: สำหรับใช้ฟอนต์ภาษาไทย `Prompt` เพื่อความสวยงาม

---

### 🚀 การติดตั้งและเริ่มใช้งาน


1.  **โคลนโปรเจกต์**:
    ```bash
    git clone https://github.com/ANTMOD46/MobileDev68.git
    cd MobileDev68
    git switch crudpocketbase
    cd dssi_shop
    ```

2.  **ติดตั้ง Flutter**: ตรวจสอบให้แน่ใจว่าคุณได้ติดตั้ง [Flutter SDK](https://docs.flutter.dev/get-started/install) เรียบร้อยแล้ว

2. **เขียนโมเดล** 

``` class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}
```

3.  **ติดตั้ง PocketBase**: ดาวน์โหลดและรัน [PocketBase](https://pocketbase.io/docs/getting-started/) บนเครื่องของคุณ และสร้าง Collection ชื่อ `Product` พร้อม Fields ดังนี้:
    * `name` (type: text)
    * `description` (type: text)
    * `price` (type: number)
    * `imageUrl` (type: url)


4.  **ติดตั้ง Dependencies**:
    ```bash
    flutter pub get

    ```

5.  **เปิด server**:
    ```bash
    
    pocketbase.exe serve
    ```
    
6.  **แก้ไขการเชื่อมต่อ**:
    ในไฟล์ `generate_product.dart`  ให้แก้ไข  PocketBase เป็นของตัวเอง 
    
    รัน
     ```
    dart run scripts/generate_product.dart
    ```

7.  **รันแอปพลิเคชัน**:
    ```bash
    flutter run
    ```
    


---
