# การพัฒนา Flutter Application สำหรับสร้างทีม Pokémon

โดยผู้ใช้สามารถ

แสดงภาพโปเกม่อนที่ดึงจาก PokeAPI พร้อมชื่อและธาตุโปเกม่อน มากกว่า  100+ ตัว

เลือก Pokémon ได้สูงสุด 3 ตัว

อนุญาตให้ผู้ใช้แก้ไขชื่อทีมและลบและบันทึกไว้ด้วย GetStorage

เพิ่มการตอบสนองหรืออนิเมชั่นเมื่อเลือก/ยกเลิกการเลือกโปเกม่อน

เก็บข้อมูลทีม (ชื่อ + ภาพ) ให้โหลดใหม่เมื่อเปิดแอป

เพิ่มปุ่ม “Reset Team” เพื่อเคลียร์การเลือกทั้งหมด

ตัวเลือกเสริม: เพิ่มแถบค้นหาชื่อโมเกม่อนและกรองธาตุเพื่อกรองโปเกม่อนในรายการ

# ข้อกำหนด (Requirements)

ติดตั้งเบื้องต้น

- Flutter SDK เวอร์ชัน >= 3.0
- Dart >= 3.0
- Git สำหรับ clone โปรเจกต์
- Editor เช่น VS Code หรือ Android Studio

# Dependencies
ในไฟล์ pubspec.yaml ต้องมี:

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.5
  get_storage: ^2.0.3
  http: ^1.2.0

```

# วิธีการรัน (How to Run)
- git clone https://github.com/ANTMOD46/MobileDev68.git
- cd MobileDev
- cd advanced_app
- flutter pub get
- flutter run -d web-server