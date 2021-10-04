import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:model/email/attachment.dart';
import 'package:tmail_ui_user/features/composer/domain/state/upload_attachment_state.dart';
import 'package:tmail_ui_user/features/composer/presentation/composer_controller.dart';
import 'package:tmail_ui_user/features/composer/presentation/widgets/email_address_composer_widget_builder.dart';
import 'package:tmail_ui_user/features/composer/presentation/widgets/top_bar_composer_widget_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/attachment_file_tile_builder.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

class ComposerView extends GetWidget<ComposerController> {

  final responsiveUtils = Get.find<ResponsiveUtils>();
  final imagePaths = Get.find<ImagePaths>();
  final keyboardUtils = Get.find<KeyboardUtils>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.primaryLightColor,
        body: SafeArea(
          right: false,
          left: false,
          child: Container(
            margin: EdgeInsets.zero,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildTopBar(context),
                Expanded(child: Container(
                  color: AppColor.bgComposer,
                  margin: EdgeInsets.zero,
                  alignment: Alignment.topCenter,
                  child: _buildBodyComposer(context)))
            ])
          )
        ),
      )
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Obx(() => (TopBarComposerWidgetBuilder(imagePaths, controller.isEnableEmailSendButton.value)
          ..addSendEmailActionClick(() => controller.sendEmailAction(context))
          ..addAttachFileActionClick(() => controller.openPickAttachmentMenu(context, _pickAttachmentsActionTiles(context)))
          ..addBackActionClick(() => controller.backToEmailViewAction()))
        .build()),
    );
  }

  List<Widget> _pickAttachmentsActionTiles(BuildContext context) {
    return [
      _pickPhotoAndVideoAction(context),
      _browseFileAction(context),
      SizedBox(height: 30),
    ];
  }

  Widget _pickPhotoAndVideoAction(BuildContext context) {
    return (SimpleContextMenuActionBuilder(
            Key('pick_photo_and_video_context_menu_action'),
            SvgPicture.asset(imagePaths.icPhotoLibrary, width: 24, height: 24, fit: BoxFit.fill),
            AppLocalizations.of(context).photos_and_videos)
        ..onActionClick((_) => controller.openFilePickerByType(context, FileType.media)))
      .build();
  }

  Widget _browseFileAction(BuildContext context) {
    return (SimpleContextMenuActionBuilder(
            Key('browse_file_context_menu_action'),
            SvgPicture.asset(imagePaths.icMore, width: 24, height: 24, fit: BoxFit.fill),
            AppLocalizations.of(context).browse)
        ..onActionClick((_) => controller.openFilePickerByType(context, FileType.any)))
      .build();
  }

  Widget _buildEmailHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.only(top: 20),
      color: AppColor.bgComposer,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _buildEmailAddress(context)),
          _buildSubjectEmail(context),
          Divider(color: AppColor.dividerColor, height: 1)
        ],
      ),
    );
  }
  
  Widget _buildEmailAddress(BuildContext context) {
    return Obx(() => (EmailAddressComposerWidgetBuilder(
            context,
            imagePaths,
            controller.expandMode.value,
            controller.listToEmailAddress,
            controller.listCcEmailAddress,
            controller.listBccEmailAddress,
            controller.composerArguments.value?.userProfile)
        ..addExpandAddressActionClick(() => controller.expandEmailAddressAction())
        ..addOnUpdateListEmailAddressAction((prefixEmailAddress, listEmailAddress) => controller.updateListEmailAddress(prefixEmailAddress, listEmailAddress))
        ..addOnSuggestionEmailAddress((word) => controller.getAutoCompleteSuggestion(word)))
      .build()
    );
  }

  Widget _buildSubjectEmail(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: 10, top: 8),
      child: (TextFieldBuilder()
            ..key(Key('subject_email_input'))
            ..textInputAction(TextInputAction.newline)
            ..maxLines(null)
            ..onChange((value) => controller.setSubjectEmail(value))
            ..textStyle(TextStyle(color: AppColor.nameUserColor, fontSize: 14, fontWeight: FontWeight.w500))
            ..textDecoration(InputDecoration(
                hintText: AppLocalizations.of(context).subject_email,
                hintStyle: TextStyle(color: AppColor.baseTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                contentPadding: EdgeInsets.zero,
                filled: true,
                border: InputBorder.none,
                fillColor: AppColor.bgComposer))
            ..addController(controller.subjectEmailInputController))
        .build()
    );
  }

  Widget _buildBodyComposer(BuildContext context) {
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Column(
        children: [
          _buildEmailHeader(context),
          Padding(
            padding: EdgeInsets.only(bottom: 30, top: 16, left: 16, right: 16),
            child: _buildComposerEditor(context),
          ),
          _buildAttachmentsLoadingView(),
          _buildAttachments(context),
        ]
      )
    );
  }

  Widget _buildComposerEditor(BuildContext context) {
    return HtmlEditor(
      key: Key('email_body_editor_quoted'),
      controller: controller.composerEditorController,
      htmlEditorOptions: HtmlEditorOptions(
        hint: AppLocalizations.of(context).hint_content_email_composer,
        shouldEnsureVisible: true),
      otherOptions: OtherOptions(decoration: BoxDecoration()),
      callbacks: Callbacks(
        onFocus: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onInit: () {
          controller.initContentEmail();
        }
      ),
    );
  }

  Widget _buildAttachmentsLoadingView() {
    return Obx(() => controller.viewState.value.fold(
      (failure) => SizedBox.shrink(),
      (success) => success is UploadingAttachmentState
        ? Center(child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppColor.primaryColor))))
        : SizedBox.shrink()));
  }

  Widget _buildAttachments(BuildContext context) {
    return Obx(() => controller.attachments.isNotEmpty
      ? ListView.builder(
          shrinkWrap: true,
          primary: false,
          key: Key('attachment_list'),
          padding: EdgeInsets.only(top: 16, bottom: 24, right: 50, left: 24),
          itemCount: controller.attachments.length,
          itemBuilder: (context, index) => (AttachmentFileTileBuilder(
                  imagePaths,
                  controller.attachments[index],
                  0,
                  0)
              ..height(60)
              ..addButtonAction(_buildRemoveButtonAttachment(controller.attachments[index])))
            .build())
      : SizedBox.shrink());
  }

  Widget _buildRemoveButtonAttachment(Attachment attachment) {
    return (IconBuilder(imagePaths.icComposerClose)
        ..size(35)
        ..addOnTapActionClick(() => controller.removeAttachmentAction(attachment)))
      .build();
  }
}