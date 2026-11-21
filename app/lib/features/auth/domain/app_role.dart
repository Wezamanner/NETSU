enum AppRole { resident, worker, admin }

AppRole? appRoleFromString(String? value) {
  return switch (value) {
    'resident' => AppRole.resident,
    'worker' => AppRole.worker,
    'admin' => AppRole.admin,
    _ => null,
  };
}
