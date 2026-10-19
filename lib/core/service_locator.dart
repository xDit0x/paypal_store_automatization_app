import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/core/network/dio_client.dart';
import 'package:store_automatization_app/data/datasources/agent_repository/supabase_agent_datasource.dart';
import 'package:store_automatization_app/data/datasources/auth_repository/supabase_auth_datasource.dart';
import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_product_datasource.dart';
import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_supplier_datasource.dart';
import 'package:store_automatization_app/data/datasources/invoice_repository/supabase_invoice_datasource.dart';
import 'package:store_automatization_app/data/datasources/orders_repository/supabase_order_datasource.dart';
import 'package:store_automatization_app/data/datasources/settings_repository/supabase_settings_datasource.dart';
import 'package:store_automatization_app/data/datasources/store_repository/supabase_store_datasource.dart';
import 'package:store_automatization_app/data/repositories/agent_repository/supabase_agent_repository.dart';
import 'package:store_automatization_app/data/repositories/auth_repository/supabase_auth_repository.dart';
import 'package:store_automatization_app/data/repositories/catalog_repository/supabase_product_repository.dart';
import 'package:store_automatization_app/data/repositories/catalog_repository/supabase_supplier_repository.dart';
import 'package:store_automatization_app/data/repositories/invoice_repository/supabase_invoice_repository.dart';
import 'package:store_automatization_app/data/repositories/orders_repository/supabase_order_repository.dart';
import 'package:store_automatization_app/data/repositories/settings_repository/supabase_settings_repository.dart';
import 'package:store_automatization_app/data/repositories/store_repository/supabase_store_repository.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';
import 'package:store_automatization_app/domain/repositories/invoice_repository/invoice_repository.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';
import 'package:store_automatization_app/domain/repositories/supplier_repository/supplier_repository.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/check_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/send_reset_password_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_out_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_up_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/watch_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_low_stock_products_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/search_product_by_uid_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/create_draft_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/evaluate_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/update_store_usecase.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<Dio>(() => DioClient.create());

  sl.registerLazySingleton<SupabaseAuthDatasource>(
    () => SupabaseAuthDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseSupplierDatasource>(
    () => SupabaseSupplierDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseProductDatasource>(
    () => SupabaseProductDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseOrderDatasource>(
    () => SupabaseOrderDatasource(sl<SupabaseClient>(), sl<Dio>()),
  );
  sl.registerLazySingleton<SupabaseInvoiceDatasource>(
    () => SupabaseInvoiceDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseSettingsDatasource>(
    () => SupabaseSettingsDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseStoreDatasource>(
    () => SupabaseStoreDatasource(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SupabaseAgentDatasource>(
    () => SupabaseAgentDatasource(sl<SupabaseClient>(), sl<Dio>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(sl<SupabaseAuthDatasource>()),
  );
  sl.registerLazySingleton<SupplierRepository>(
    () => SupabaseSupplierRepository(sl<SupabaseSupplierDatasource>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => SupabaseProductRepository(sl<SupabaseProductDatasource>()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => SupabaseOrderRepository(sl<SupabaseOrderDatasource>()),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => SupabaseInvoiceRepository(sl<SupabaseInvoiceDatasource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SupabaseSettingsRepository(sl<SupabaseSettingsDatasource>()),
  );
  sl.registerLazySingleton<StoreRepository>(
    () => SupabaseStoreRepository(sl<SupabaseStoreDatasource>()),
  );
  sl.registerLazySingleton<AgentRepository>(
    () => SupabaseAgentRepository(sl<SupabaseAgentDatasource>()),
  );

  sl.registerLazySingleton(
    () => SignInUsecase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SignUpUsecase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SignOutUsecase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => CheckAuthUsecase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => WatchAuthUsecase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SendResetPasswordEmailUsecase(repository: sl<AuthRepository>()),
  );

  sl.registerLazySingleton(
    () => GetSuppliersUsecase(repository: sl<SupplierRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSupplierCatalogUsecase(repository: sl<ProductRepository>()),
  );
  sl.registerLazySingleton(
    () => SearchProductByUidUsecase(repository: sl<ProductRepository>()),
  );
  sl.registerLazySingleton(
    () => GetLowStockProductsUsecase(repository: sl<ProductRepository>()),
  );
  sl.registerLazySingleton(() => const EvaluateSpendingRulesUsecase());
  sl.registerLazySingleton(
    () => CreateDraftOrderUsecase(
      productRepository: sl<ProductRepository>(),
      orderRepository: sl<OrderRepository>(),
      evaluateSpendingRules: sl<EvaluateSpendingRulesUsecase>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetOrdersUsecase(repository: sl<OrderRepository>()),
  );
  sl.registerLazySingleton(
    () => GetOrderUsecase(repository: sl<OrderRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSpentThisMonthUsecase(repository: sl<OrderRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCurrentStoreUsecase(repository: sl<StoreRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateStoreUsecase(repository: sl<StoreRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSpendingRulesUsecase(repository: sl<SettingsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateSpendingRulesUsecase(repository: sl<SettingsRepository>()),
  );
  sl.registerLazySingleton(
    () => RunAgentUsecase(repository: sl<AgentRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAgentRunsUsecase(repository: sl<AgentRepository>()),
  );

  sl.registerLazySingleton(
    () => AuthCubit(
      signInUseCase: sl<SignInUsecase>(),
      signUpUseCase: sl<SignUpUsecase>(),
      signOutUseCase: sl<SignOutUsecase>(),
      checkAuthUseCase: sl<CheckAuthUsecase>(),
      watchAuthUseCase: sl<WatchAuthUsecase>(),
      sendResetPasswordEmailUseCase: sl<SendResetPasswordEmailUsecase>(),
    ),
  );
}
