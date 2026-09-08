enum SyncStatus {
  pending,  // Creado localmente
  syncing,  // En proceso de subida
  synced,   // Confirmado en la nube
  failed    // Error en el intento
}