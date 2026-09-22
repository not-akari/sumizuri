bool shouldPopUpNotification({
  required bool appFocused,
  required bool hideWhileInApp,
}) => !(appFocused && hideWhileInApp);
