import 'package:flutter/widgets.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

/// [error] in the language the reader chose.
String hymnsErrorText(BuildContext context, HymnsError error) {
  final l = AppLocalizations.of(context);
  final number = error.number ?? 0;
  return switch (error.kind) {
    HymnsErrorKind.loadFailed =>
      l?.errorHymnsLoadFailed ?? 'መዝሙሮቹን መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
    HymnsErrorKind.needsConnection => l?.errorNeedsConnection ??
        'ይህ የመዝሙር ስብስብ ለመጀመሪያ ጊዜ ሲከፈት የኢንተርኔት ግንኙነት '
            'ያስፈልገዋል። እባክዎ ይገናኙና እንደገና ይሞክሩ።',
    HymnsErrorKind.editionUnavailable => l?.errorEditionUnavailable ??
        'ይህ የመዝሙር ስብስብ ከአሁን በኋላ አይገኝም። እባክዎ በቅንብሮች ውስጥ '
            'ሌላ ይምረጡ።',
    HymnsErrorKind.searchFailed =>
      l?.errorSearchFailed ?? 'ፍለጋው አልተሳካም። እባክዎ እንደገና ይሞክሩ።',
    HymnsErrorKind.notFound =>
      l?.hymnNotFoundNumber(number) ?? 'መዝሙር ቁጥር $number አልተገኘም',
    HymnsErrorKind.lookupFailed => l?.errorHymnLookupFailed(number) ??
        'መዝሙር ቁጥር $number መክፈት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
  };
}
