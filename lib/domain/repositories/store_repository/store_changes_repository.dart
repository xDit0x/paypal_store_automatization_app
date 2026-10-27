/// Avisa cuando cambia algo de una tienda en la base de datos (pedidos,
/// stock o ejecuciones del agente), venga de donde venga el cambio.
abstract class StoreChangesRepository {
  /// Emite un evento por cada cambio. Cancelar la suscripción cierra la
  /// conexión en tiempo real.
  Stream<void> watch(String storeId);
}
