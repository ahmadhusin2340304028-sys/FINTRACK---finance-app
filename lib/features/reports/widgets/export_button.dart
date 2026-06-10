import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/report_provider.dart';

class ExportButton extends ConsumerWidget {
  const ExportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(reportExportProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: exportState.isExporting
                  ? null
                  : () async {
                      final path = await ref
                          .read(reportExportProvider.notifier)
                          .exportCsv();
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('CSV berhasil dibuat'),
                            action: SnackBarAction(
                              label: 'Buka',
                              onPressed: () => OpenFile.open(path),
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.table_chart_outlined,
                  color: AppColors.success),
              label: const Text('Export CSV',
                  style: TextStyle(color: AppColors.success)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: exportState.isExporting
                  ? null
                  : () async {
                      final path = await ref
                          .read(reportExportProvider.notifier)
                          .exportPdf();
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('PDF berhasil dibuat'),
                            action: SnackBarAction(
                              label: 'Buka',
                              onPressed: () => OpenFile.open(path),
                            ),
                          ),
                        );
                      }
                    },
              icon: exportState.isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white),
              label: Text(
                exportState.isExporting ? 'Membuat...' : 'Export PDF',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
