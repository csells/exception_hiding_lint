import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/exception_hiding_rule.dart';

PluginBase createPlugin() => _ExceptionHidingLint();

class _ExceptionHidingLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ExceptionHidingRule(),
      ];
}
