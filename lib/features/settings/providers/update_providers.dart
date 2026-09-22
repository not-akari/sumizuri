import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/settings/data/github_update_checker.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';

part 'update_providers.g.dart';

@Riverpod(keepAlive: true)
UpdateChecker updateChecker(Ref ref) => GitHubUpdateChecker();
