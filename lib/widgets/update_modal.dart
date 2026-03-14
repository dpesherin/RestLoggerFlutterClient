import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/update_modal_controller.dart';
import '../services/update_service.dart';
import '../utils/theme.dart';
import 'toast_widget.dart';

class UpdateModal extends StatefulWidget {
  final bool autoStartCheck;
  final bool dismissIfNoUpdate;
  final UpdateCheckResult? initialResult;

  const UpdateModal({
    super.key,
    this.autoStartCheck = false,
    this.dismissIfNoUpdate = false,
    this.initialResult,
  });

  @override
  State<UpdateModal> createState() => _UpdateModalState();
}

class _UpdateModalState extends State<UpdateModal> {
  late final UpdateModalController _controller;

  UpdateCheckResult? get _result => _controller.result;
  bool get _isLoading => _controller.isLoading;
  bool get _isInstalling => _controller.isInstalling;
  bool get _autoCheckEnabled => _controller.autoCheckEnabled;
  String? get _errorMessage => _controller.errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = UpdateModalController()..addListener(_handleController);
    _controller.initialize(
      autoStartCheck: widget.autoStartCheck,
      initialResult: widget.initialResult,
    );
  }

  void _handleController() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleAutoCheck(bool value) async {
    await _controller.toggleAutoCheck(value);
  }

  Future<void> _checkForUpdates() async {
    final shouldStayOpen = await _controller.checkForUpdates(
      dismissIfNoUpdate: widget.dismissIfNoUpdate,
    );
    if (!mounted) return;
    if (widget.dismissIfNoUpdate && !shouldStayOpen) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _installUpdate() async {
    if (_result?.updateInfo == null || _isInstalling) return;

    try {
      final installResult = await _controller.installUpdate();
      if (!mounted) return;

      ToastWidget.show(
        context,
        message: installResult.message,
        type: installResult.started ? ToastType.success : ToastType.warning,
      );

      if (installResult.started) {
        Navigator.of(context).pop(true);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        exit(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final update = result?.updateInfo;
    final hasUpdate = result?.hasUpdate == true && update != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: 620,
            decoration: context.panelDecoration(radius: 30).copyWith(
                  color: context.appPanel.withValues(alpha: 0.66),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: context.appBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          hasUpdate
                              ? Icons.system_update_alt_rounded
                              : Icons.info_outline_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasUpdate
                                  ? 'Доступно обновление'
                                  : 'Обновления приложения',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_controller.currentPlatform} • версия ${_controller.currentVersion}',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Закрыть',
                        style: IconButton.styleFrom(
                          backgroundColor: context.appPanelAlt,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        'Текущая версия',
                        _controller.currentVersion,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        context,
                        'Платформа',
                        _controller.currentPlatform,
                      ),
                      if (result != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Статус',
                          hasUpdate
                              ? 'Доступна версия ${update.fullVersion}'
                              : 'Установлена актуальная версия',
                        ),
                      ],
                      if (update != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Новая версия',
                          update.fullVersion,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Файл',
                          update.fileName,
                        ),
                        if (update.publishedAt != null) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            context,
                            'Дата публикации',
                            update.publishedAt!,
                          ),
                        ],
                        if ((update.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Что нового',
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.appPanelAlt.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.appBorder),
                            ),
                            child: Text(
                              update.notes!,
                              style: TextStyle(
                                color: context.appTextMuted,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: context.appPanelAlt.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          title: Text(
                            'Проверять обновления автоматически',
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _autoCheckEnabled
                                ? 'При запуске приложение будет проверять наличие новых версий'
                                : 'Проверка будет выполняться только по кнопке',
                            style: TextStyle(color: context.appTextMuted),
                          ),
                          value: _autoCheckEnabled,
                          onChanged: _toggleAutoCheck,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD94B62).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD94B62)
                                  .withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFD94B62)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.appBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading || _isInstalling
                              ? null
                              : _checkForUpdates,
                          style: TextButton.styleFrom(
                            backgroundColor: context.appPanelAlt,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  hasUpdate
                                      ? 'Проверить снова'
                                      : 'Проверить обновления',
                                  style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      if (hasUpdate) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInstalling ? null : _installUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isInstalling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Установить обновление',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
