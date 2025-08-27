import 'package:get_it/get_it.dart';
import '../core/services/counter_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // ลงทะเบียนเป็น singleton ครั้งเดียว ใช้ทั้งแอป
  getIt.registerSingleton<CounterService>(CounterService());
}
