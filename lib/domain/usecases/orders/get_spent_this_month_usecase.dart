import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class GetSpentThisMonthUsecase {
  final OrderRepository repository;
  GetSpentThisMonthUsecase({required this.repository});

  Future<Either<String, double>> call(String storeId) =>
      repository.getSpentThisMonth(storeId);
}
