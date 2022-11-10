import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/utils/app_logger.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/sort/comparator.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator_property.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_filter_condition.dart';
import 'package:jmap_dart_client/jmap/mail/email/keyword_identifier.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/model.dart';
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/features/caching/caching_manager.dart';
import 'package:tmail_ui_user/features/composer/domain/state/save_email_as_drafts_state.dart';
import 'package:tmail_ui_user/features/composer/domain/state/send_email_state.dart';
import 'package:tmail_ui_user/features/composer/domain/state/update_email_drafts_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_email_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_multiple_emails_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_read_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_star_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/move_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/mark_as_mailbox_read_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/state/remove_email_drafts_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/dashboard_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/search_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/dashboard_routes.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/search_email_filter.dart';
import 'package:tmail_ui_user/features/search/presentation/search_email_bindings.dart';
import 'package:tmail_ui_user/features/thread/domain/constants/thread_constants.dart';
import 'package:tmail_ui_user/features/thread/domain/model/email_filter.dart';
import 'package:tmail_ui_user/features/thread/domain/model/filter_message_option.dart';
import 'package:tmail_ui_user/features/thread/domain/model/get_email_request.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/features/thread/domain/state/empty_trash_folder_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_all_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_email_by_id_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/load_more_emails_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_multiple_email_read_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_star_multiple_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/move_multiple_email_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/refresh_changes_all_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/search_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/search_more_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_email_by_id_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/load_more_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/refresh_changes_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/search_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/search_more_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/presentation/mixin/email_action_controller.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/delete_action_type.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/search_state.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/search_status.dart';
import 'package:tmail_ui_user/main/exceptions/remote_exception.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/navigation_router.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';
import 'package:tmail_ui_user/main/routes/route_utils.dart';

typedef StartRangeSelection = int;
typedef EndRangeSelection = int;

class ThreadController extends BaseController with EmailActionController {

  final _imagePaths = Get.find<ImagePaths>();
  final _appToast = Get.find<AppToast>();

  final GetEmailsInMailboxInteractor _getEmailsInMailboxInteractor;
  final RefreshChangesEmailsInMailboxInteractor _refreshChangesEmailsInMailboxInteractor;
  final LoadMoreEmailsInMailboxInteractor _loadMoreEmailsInMailboxInteractor;
  final SearchEmailInteractor _searchEmailInteractor;
  final SearchMoreEmailInteractor _searchMoreEmailInteractor;
  final CachingManager _cachingManager;
  final GetEmailByIdInteractor _getEmailByIdInteractor;

  final listEmailDrag = <PresentationEmail>[].obs;
  bool _rangeSelectionMode = false;
  bool canLoadMore = true;
  bool canSearchMore = true;
  bool _isLoadingMore = false;
    get isLoadingMore => _isLoadingMore;
  MailboxId? _currentMailboxId;
  jmap.State? _currentEmailState;
  final ScrollController listEmailController = ScrollController();
  final FocusNode focusNodeKeyBoard = FocusNode();
  final latestEmailSelectedOrUnselected = Rxn<PresentationEmail>();
  late Worker mailboxWorker, searchWorker, dashboardActionWorker, viewStateWorker, advancedSearchFilterWorker;

  Set<Comparator>? get _sortOrder => <Comparator>{}
    ..add(EmailComparator(EmailComparatorProperty.receivedAt)
      ..setIsAscending(false));

  AccountId? get _accountId => mailboxDashBoardController.accountId.value;

  PresentationMailbox? get currentMailbox => mailboxDashBoardController.selectedMailbox.value;

  SearchController get searchController => mailboxDashBoardController.searchController;

  SearchEmailFilter get _searchEmailFilter => searchController.searchEmailFilter.value;

  String get currentTextSearch => searchController.searchInputController.text;

  SearchQuery? get searchQuery => searchController.searchEmailFilter.value.text;

  RxList<PresentationEmail> get emailList => mailboxDashBoardController.emailsInCurrentMailbox;

  ThreadController(
    this._getEmailsInMailboxInteractor,
    this._refreshChangesEmailsInMailboxInteractor,
    this._loadMoreEmailsInMailboxInteractor,
    this._searchEmailInteractor,
    this._searchMoreEmailInteractor,
    this._cachingManager,
    this._getEmailByIdInteractor,
  );

  @override
  void onInit() {
    _registerListenerWorker();
    super.onInit();
  }

  @override
  void onReady() {
    dispatchState(Right(LoadingState()));
    super.onReady();
  }

  @override
  void onClose() {
    listEmailController.dispose();
    focusNodeKeyBoard.dispose();
    _unregisterListenerWorker();
    super.onClose();
  }

  @override
  void onData(Either<Failure, Success> newState) {
    super.onData(newState);
    newState.fold(
      (failure) {
        if (failure is SearchEmailFailure) {
          emailList.clear();
        } else if (failure is SearchMoreEmailFailure || failure is LoadMoreEmailsFailure) {
          _isLoadingMore = false;
        }
      },
      (success) {
        if (success is GetAllEmailSuccess) {
          _getAllEmailSuccess(success);
        } else if (success is RefreshChangesAllEmailSuccess) {
          _refreshChangesAllEmailSuccess(success);
        } else if (success is LoadMoreEmailsSuccess) {
          _loadMoreEmailsSuccess(success);
        } else if (success is SearchEmailSuccess) {
          _searchEmailsSuccess(success);
        } else if (success is SearchMoreEmailSuccess) {
          _searchMoreEmailsSuccess(success);
        } else if (success is SearchingMoreState || success is LoadingMoreState) {
          _isLoadingMore = true;
        } else if (success is GetEmailByIdSuccess) {
          if (currentContext != null) {
            final mailboxContain = success.email
              .findMailboxContain(mailboxDashBoardController.mapMailboxById);
            final route = RouteUtils.generateRouteBrowser(
              AppRoutes.dashboard,
              NavigationRouter(
                emailId: success.email.id,
                mailboxId: mailboxContain?.id,
                dashboardType: searchController.isSearchEmailRunning
                  ? DashboardType.search
                  : DashboardType.normal
              )
            );
            pressEmailAction(
              currentContext!,
              EmailActionType.preview,
              success.email.withRouteWeb(route),
              mailboxContain: mailboxContain);
          }
        }
      }
    );
  }

  @override
  void onDone() {}

  @override
  void onError(error) {
    _handleErrorGetAllOrRefreshChangesEmail(error);
  }

  void _registerListenerWorker() {
    mailboxWorker = ever(mailboxDashBoardController.selectedMailbox, (mailbox) {
      if (mailbox is PresentationMailbox) {
        if (_currentMailboxId != mailbox.id) {
          _currentMailboxId = mailbox.id;
          _resetToOriginalValue();
          _getAllEmail();
        }
      } else if (mailbox == null) { // disable current mailbox when search active
        _currentMailboxId = null;
        _resetToOriginalValue();
      }
    });

    searchWorker = ever(searchController.searchState, (searchState) {
      if (searchState is SearchState) {
        if (searchState.searchStatus == SearchStatus.ACTIVE) {
          cancelSelectEmail();
        }
      }
    });

    advancedSearchFilterWorker = ever(searchController.isAdvancedSearchViewOpen, (hasOpen) {
      if (hasOpen == true) {
        mailboxDashBoardController.filterMessageOption.value = FilterMessageOption.all;
      }
    });

    dashboardActionWorker = ever(mailboxDashBoardController.dashBoardAction, (action) {
      if (action is RefreshAllEmailAction) {
        refreshAllEmail();
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is SelectionAllEmailAction) {
        setSelectAllEmailAction();
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is CancelSelectionAllEmailAction) {
        cancelSelectEmail();
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is FilterMessageAction) {
        filterMessagesAction(action.context, action.option);
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is HandleEmailActionTypeAction) {
        pressEmailSelectionAction(action.context, action.emailAction, action.listEmailSelected);
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is OpenEmailDetailedFromSuggestionQuickSearchAction) {
        final mailboxContain = action.presentationEmail
            .findMailboxContain(mailboxDashBoardController.mapMailboxById);
        final route = RouteUtils.generateRouteBrowser(
          AppRoutes.dashboard,
          NavigationRouter(
            emailId: action.presentationEmail.id,
            mailboxId: mailboxContain?.id,
            dashboardType: searchController.isSearchEmailRunning
              ? DashboardType.search
              : DashboardType.normal
          )
        );
        pressEmailAction(
            action.context,
            EmailActionType.preview,
            action.presentationEmail.withRouteWeb(route),
            mailboxContain: mailboxContain);
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is StartSearchEmailAction) {
        cancelSelectEmail();
        _searchEmail();
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is EmptyTrashAction) {
        deleteSelectionEmailsPermanently(action.context, DeleteActionType.all);
        mailboxDashBoardController.clearDashBoardAction();
      } else if (action is SelectEmailByIdAction) {
        _openEmailDetailedView(action.emailId);
        mailboxDashBoardController.clearDashBoardAction();
      }
    });

    viewStateWorker = ever(mailboxDashBoardController.viewState, (viewState) {
      if (viewState is Either) {
        viewState.map((success) {
          if (success is MarkAsEmailReadSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MoveToMailboxSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsStarEmailSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is DeleteEmailPermanentlySuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is SaveEmailAsDraftsSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is RemoveEmailDraftsSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is SendEmailSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is UpdateEmailDraftsSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsMailboxReadAllSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsMailboxReadHasSomeEmailFailure) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MoveMultipleEmailToMailboxAllSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MoveMultipleEmailToMailboxHasSomeEmailFailure) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is DeleteMultipleEmailsPermanentlyAllSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is DeleteMultipleEmailsPermanentlyHasSomeEmailFailure) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsStarMultipleEmailAllSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsStarMultipleEmailHasSomeEmailFailure) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsMultipleEmailReadAllSuccess) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is MarkAsMultipleEmailReadHasSomeEmailFailure) {
            _refreshEmailChanges(currentEmailState: success.currentEmailState);
          } else if (success is EmptyTrashFolderSuccess) {
            refreshAllEmail();
          }
        });
      }
    });
  }

  void _unregisterListenerWorker() {
    mailboxWorker.dispose();
    dashboardActionWorker.dispose();
    searchWorker.dispose();
    advancedSearchFilterWorker.dispose();
    viewStateWorker.dispose();
  }

  void _handleErrorGetAllOrRefreshChangesEmail(dynamic error) async {
    logError('ThreadController::_handleErrorGetAllOrRefreshChangesEmail():Error: $error');
    if (error is CannotCalculateChangesMethodResponseException) {
      await _cachingManager.cleanEmailCache();
      _getAllEmail();
    } else {
      super.onError(error);
    }
  }

  void _getAllEmail() {
    if (_accountId != null) {
      _getAllEmailAction(_accountId!, mailboxId: _currentMailboxId);
    }
  }

  void _resetToOriginalValue() {
    dispatchState(Right(LoadingState()));
    emailList.clear();
    canLoadMore = true;
    _isLoadingMore = false;
    cancelSelectEmail();
    mailboxDashBoardController.dispatchRoute(DashboardRoutes.thread);
  }

  void _getAllEmailSuccess(GetAllEmailSuccess success) {
    _currentEmailState = success.currentEmailState;
    log('ThreadController::_getAllEmailSuccess():_currentEmailState: $_currentEmailState');
    emailList.value = success.emailList;
    if (listEmailController.hasClients) {
      listEmailController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.fastOutSlowIn);
    }
  }

  void _refreshChangesAllEmailSuccess(RefreshChangesAllEmailSuccess success) {
    _currentEmailState = success.currentEmailState;

    final emailsBeforeChanges = emailList;
    final emailsAfterChanges = success.emailList;
    final newListEmail = emailsAfterChanges.combine(emailsBeforeChanges);
    emailList.value = newListEmail;

    if (emailList.isEmpty) {
      refreshAllEmail();
    }
  }

  void _getAllEmailAction(AccountId accountId, {MailboxId? mailboxId}) {
    consumeState(_getEmailsInMailboxInteractor.execute(
      accountId,
      limit: ThreadConstants.defaultLimit,
      sort: _sortOrder,
      emailFilter: EmailFilter(
        filter: _getFilterCondition(),
        filterOption: mailboxDashBoardController.filterMessageOption.value,
        mailboxId: mailboxId ?? _currentMailboxId),
      propertiesCreated: ThreadConstants.propertiesDefault,
      propertiesUpdated: ThreadConstants.propertiesUpdatedDefault,
    ));
  }

  EmailFilterCondition _getFilterCondition({bool isLoadMore = false}) {
    switch(mailboxDashBoardController.filterMessageOption.value) {
      case FilterMessageOption.all:
        return EmailFilterCondition(
          inMailbox: mailboxDashBoardController.selectedMailbox.value?.id,
          before: isLoadMore ? emailList.last.receivedAt : null
        );
      case FilterMessageOption.unread:
        return EmailFilterCondition(
            inMailbox: mailboxDashBoardController.selectedMailbox.value?.id,
            notKeyword: KeyWordIdentifier.emailSeen.value,
            before: isLoadMore ? emailList.last.receivedAt : null
        );
      case FilterMessageOption.attachments:
        return EmailFilterCondition(
            inMailbox: mailboxDashBoardController.selectedMailbox.value?.id,
            hasAttachment: true,
            before: isLoadMore ? emailList.last.receivedAt : null
        );
      case FilterMessageOption.starred:
        return EmailFilterCondition(
            inMailbox: mailboxDashBoardController.selectedMailbox.value?.id,
            hasKeyword: KeyWordIdentifier.emailFlagged.value,
            before: isLoadMore ? emailList.last.receivedAt : null
        );
    }
  }

  void refreshAllEmail() {
    dispatchState(Right(LoadingState()));
    canLoadMore = true;
    cancelSelectEmail();

    if (searchController.isSearchEmailRunning) {
      final limit = emailList.isNotEmpty ? UnsignedInt(emailList.length) : ThreadConstants.defaultLimit;
      searchController.searchEmailFilter.value = _searchEmailFilter.clearBeforeDate();
      _searchEmail(limit: limit);
    } else {
      _getAllEmail();
    }
  }

  void _refreshEmailChanges({jmap.State? currentEmailState}) {
    log('ThreadController::_refreshEmailChanges(): currentEmailState: $currentEmailState');
    if (searchController.isSearchEmailRunning) {
      final limit = emailList.isNotEmpty ? UnsignedInt(emailList.length) : ThreadConstants.defaultLimit;
      searchController.searchEmailFilter.value = _searchEmailFilter.clearBeforeDate();
      _searchEmail(limit: limit);
    } else {
      final newEmailState = currentEmailState ?? _currentEmailState;
      log('ThreadController::_refreshEmailChanges(): newEmailState: $newEmailState');
      if (_accountId != null && newEmailState != null) {
        consumeState(_refreshChangesEmailsInMailboxInteractor.execute(
            _accountId!,
            newEmailState,
            sort: _sortOrder,
            propertiesCreated: ThreadConstants.propertiesDefault,
            propertiesUpdated: ThreadConstants.propertiesUpdatedDefault,
            emailFilter: EmailFilter(
              filter: _getFilterCondition(),
              filterOption: mailboxDashBoardController.filterMessageOption.value,
              mailboxId: _currentMailboxId),
        ));
      }
    }
  }

  void loadMoreEmails() {
    log('ThreadController::loadMoreEmails()');
    if (canLoadMore && _accountId != null) {
      consumeState(_loadMoreEmailsInMailboxInteractor.execute(
        GetEmailRequest(
            _accountId!,
            limit: ThreadConstants.defaultLimit,
            sort: _sortOrder,
            filterOption: mailboxDashBoardController.filterMessageOption.value,
            filter: _getFilterCondition(isLoadMore: true),
            properties: ThreadConstants.propertiesDefault,
            lastEmailId: emailList.last.id)
      ));
    }
  }

  bool _belongToCurrentMailboxId(PresentationEmail email) {
    return (email.mailboxIds != null && email.mailboxIds!.keys.contains(currentMailbox?.id));
  }

  bool _notDuplicatedInCurrentList(PresentationEmail email) {
    return emailList.isEmpty || !emailList.map((element) => element.id).contains(email.id);
  }

  void _loadMoreEmailsSuccess(LoadMoreEmailsSuccess success) {
    if (success.emailList.isNotEmpty) {
      final appendableList = success.emailList
        .where(_belongToCurrentMailboxId)
        .where(_notDuplicatedInCurrentList);

      emailList.addAll(appendableList);
    } else {
      canLoadMore = false;
    }
    _isLoadingMore = false;
  }

  SelectMode getSelectMode(PresentationEmail presentationEmail, PresentationEmail? selectedEmail) {
    return presentationEmail.id == selectedEmail?.id
      ? SelectMode.ACTIVE
      : SelectMode.INACTIVE;
  }

  void previewEmail(BuildContext context, PresentationEmail presentationEmailSelected) {
    mailboxDashBoardController.setSelectedEmail(presentationEmailSelected);
    mailboxDashBoardController.dispatchRoute(DashboardRoutes.emailDetailed);
  }

  Tuple2<StartRangeSelection,EndRangeSelection> _getSelectionEmailsRange(PresentationEmail presentationEmailSelected) {
    final emailSelectedIndex = emailList.indexWhere((e) => e.id == presentationEmailSelected.id);
    final latestEmailSelectedOrUnselectedIndex = emailList.indexWhere((e) => e.id == latestEmailSelectedOrUnselected.value?.id);
    if (emailSelectedIndex > latestEmailSelectedOrUnselectedIndex) {
      return Tuple2(latestEmailSelectedOrUnselectedIndex, emailSelectedIndex);
    } else {
      return Tuple2(emailSelectedIndex, latestEmailSelectedOrUnselectedIndex);
    }
  }

  bool _checkAllowMakeRangeEmailsSelected(Tuple2<StartRangeSelection,EndRangeSelection> selectionEmailsRange) {
    return latestEmailSelectedOrUnselected.value?.selectMode == SelectMode.ACTIVE &&
      !emailList.sublist(selectionEmailsRange.value1, selectionEmailsRange.value2).every((e) => e.selectMode == SelectMode.ACTIVE) ||
      latestEmailSelectedOrUnselected.value?.selectMode == SelectMode.INACTIVE &&
      emailList.sublist(selectionEmailsRange.value1, selectionEmailsRange.value2).every((e) => e.selectMode == SelectMode.INACTIVE);
  }

  void _applySelectModeToRangeEmails(Tuple2<StartRangeSelection,EndRangeSelection> selectionEmailsRange, SelectMode selectMode) {
    emailList.value = emailList.asMap().map((index, email) {
      return MapEntry(index, index >= selectionEmailsRange.value1 && index <= selectionEmailsRange.value2 ? email.toSelectedEmail(selectMode: selectMode) : email);
    }).values.toList();
  }

  void _rangeSelectionEmailsAction(PresentationEmail presentationEmailSelected) {
    final selectionEmailsRange = _getSelectionEmailsRange(presentationEmailSelected);

    if (_checkAllowMakeRangeEmailsSelected(selectionEmailsRange)) {
      _applySelectModeToRangeEmails(selectionEmailsRange, SelectMode.ACTIVE);
    } else {
      _applySelectModeToRangeEmails(selectionEmailsRange, SelectMode.INACTIVE);
    }
  }

  void selectEmail(BuildContext context, PresentationEmail presentationEmailSelected) {
    if (_rangeSelectionMode && latestEmailSelectedOrUnselected.value != null && latestEmailSelectedOrUnselected.value?.id != presentationEmailSelected.id) {
      _rangeSelectionEmailsAction(presentationEmailSelected);
    } else {
      emailList.value = emailList
        .map((email) => email.id == presentationEmailSelected.id ? email.toggleSelect() : email)
        .toList();
    }
    latestEmailSelectedOrUnselected.value = emailList.firstWhereOrNull((e) => e.id == presentationEmailSelected.id);
    focusNodeKeyBoard.requestFocus();
    if (_isUnSelectedAll()) {
      mailboxDashBoardController.currentSelectMode.value = SelectMode.INACTIVE;
      mailboxDashBoardController.listEmailSelected.clear();
    } else {
      if (mailboxDashBoardController.currentSelectMode.value == SelectMode.INACTIVE) {
        mailboxDashBoardController.currentSelectMode.value = SelectMode.ACTIVE;
      }
      mailboxDashBoardController.listEmailSelected.value = listEmailSelected;
    }
  }

  void enableSelectionEmail() {
    mailboxDashBoardController.currentSelectMode.value = SelectMode.ACTIVE;
  }

  void setSelectAllEmailAction() {
    emailList.value = emailList.map((email) => email.toSelectedEmail(selectMode: SelectMode.ACTIVE)).toList();
    mailboxDashBoardController.currentSelectMode.value = SelectMode.ACTIVE;
    mailboxDashBoardController.listEmailSelected.value = listEmailSelected;
  }

  List<PresentationEmail> get listEmailSelected => emailList.listEmailSelected;

  bool _isUnSelectedAll() {
    return emailList.every((email) => email.selectMode == SelectMode.INACTIVE);
  }

  void cancelSelectEmail() {
    emailList.value = emailList.map((email) => email.toSelectedEmail(selectMode: SelectMode.INACTIVE)).toList();
    mailboxDashBoardController.currentSelectMode.value = SelectMode.INACTIVE;
    mailboxDashBoardController.listEmailSelected.clear();
  }

  void closeFilterMessageActionSheet() {
    popBack();
  }

  void filterMessagesAction(BuildContext context, FilterMessageOption filterOption) {
    popBack();

    final newFilterOption = mailboxDashBoardController.filterMessageOption.value == filterOption
        ? FilterMessageOption.all
        : filterOption;

    mailboxDashBoardController.filterMessageOption.value = newFilterOption;

    _appToast.showToastWithIcon(
        currentOverlayContext!,
        message: newFilterOption.getMessageToast(context),
        icon: newFilterOption.getIconToast(_imagePaths));

    if (searchController.isSearchEmailRunning) {
      _searchEmail(filterCondition: _getFilterCondition());
    } else {
      refreshAllEmail();
    }
  }

  bool isSearchActive() => searchController.isSearchEmailRunning;

  bool get isAllSearchInActive => !searchController.isSearchActive() &&
    searchController.isAdvancedSearchViewOpen.isFalse;

  void clearTextSearch() {
    searchController.clearTextSearch();
  }

  void _searchEmail({UnsignedInt? limit, EmailFilterCondition? filterCondition}) {
    if (_accountId != null && searchQuery != null) {
      searchController.activateSimpleSearch();

      filterCondition = EmailFilterCondition(
        notKeyword: filterCondition?.notKeyword,
        hasKeyword: filterCondition?.hasKeyword,
        hasAttachment: filterCondition?.hasAttachment,
      );

      consumeState(_searchEmailInteractor.execute(
        _accountId!,
        limit: limit ?? ThreadConstants.defaultLimit,
        sort: _sortOrder,
        filter: _searchEmailFilter.mappingToEmailFilterCondition(moreFilterCondition: filterCondition),
        properties: ThreadConstants.propertiesDefault,
      ));
    }
  }

  void _searchEmailsSuccess(SearchEmailSuccess success) {
    final resultEmailSearchList = success.emailList
        .map((email) => email.toSearchPresentationEmail(mailboxDashBoardController.mapMailboxById))
        .toList();

    final emailsSearchBeforeChanges = emailList;
    final emailsSearchAfterChanges = resultEmailSearchList;
    final newListEmailSearch = emailsSearchAfterChanges.combine(emailsSearchBeforeChanges);
    emailList.value = newListEmailSearch;
  }

  void searchMoreEmails() {
    if (canSearchMore && _accountId != null) {
      searchController.updateFilterEmail(before: emailList.last.receivedAt);
      consumeState(_searchMoreEmailInteractor.execute(
        _accountId!,
        limit: ThreadConstants.defaultLimit,
        sort: _sortOrder,
        filter: searchController.searchEmailFilter.value.mappingToEmailFilterCondition(),
        properties: ThreadConstants.propertiesDefault,
        lastEmailId: emailList.last.id
      ));
    }
  }

  void _searchMoreEmailsSuccess(SearchMoreEmailSuccess success) {
    if (success.emailList.isNotEmpty) {
      final resultEmailSearchList = success.emailList
          .map((email) => email.toSearchPresentationEmail(mailboxDashBoardController.mapMailboxById))
          .where((email) => !emailList.contains(email))
          .toList();
      emailList.addAll(resultEmailSearchList);
    } else {
      canSearchMore = false;
    }
    _isLoadingMore = false;
  }

  bool isSelectionEnabled() => mailboxDashBoardController.isSelectionEnabled();

  void pressEmailSelectionAction(BuildContext context, EmailActionType actionType, List<PresentationEmail> selectionEmail) {
    switch(actionType) {
      case EmailActionType.markAsRead:
        cancelSelectEmail();
        markAsReadSelectedMultipleEmail(selectionEmail, ReadActions.markAsRead);
        break;
      case EmailActionType.markAsUnread:
        cancelSelectEmail();
        markAsReadSelectedMultipleEmail(selectionEmail, ReadActions.markAsUnread);
        break;
      case EmailActionType.markAsStarred:
        cancelSelectEmail();
        markAsStarSelectedMultipleEmail(selectionEmail, MarkStarAction.markStar);
        break;
      case EmailActionType.unMarkAsStarred:
        cancelSelectEmail();
        markAsStarSelectedMultipleEmail(selectionEmail, MarkStarAction.unMarkStar);
        break;
      case EmailActionType.moveToMailbox:
        cancelSelectEmail();
        final mailboxContainCurrent = searchController.isSearchEmailRunning
            ? selectionEmail.getCurrentMailboxContain(mailboxDashBoardController.mapMailboxById)
            : currentMailbox;
        if (mailboxContainCurrent != null) {
          moveSelectedMultipleEmailToMailbox(context, selectionEmail, mailboxContainCurrent);
        }
        break;
      case EmailActionType.moveToTrash:
        cancelSelectEmail();
        final mailboxContainCurrent = searchController.isSearchEmailRunning
            ? selectionEmail.getCurrentMailboxContain(mailboxDashBoardController.mapMailboxById)
            : currentMailbox;
        if (mailboxContainCurrent != null) {
          moveSelectedMultipleEmailToTrash(selectionEmail, mailboxContainCurrent);
        }
        break;
      case EmailActionType.deletePermanently:
        final mailboxContainCurrent = searchController.isSearchEmailRunning
            ? selectionEmail.getCurrentMailboxContain(mailboxDashBoardController.mapMailboxById)
            : currentMailbox;
        if (mailboxContainCurrent != null) {
          deleteSelectionEmailsPermanently(
            context,
            DeleteActionType.multiple,
            listEmails: selectionEmail,
            mailboxCurrent: mailboxContainCurrent,
            onCancelSelectionEmail: () => cancelSelectEmail());
        }
        break;
      case EmailActionType.moveToSpam:
        cancelSelectEmail();
        final mailboxContainCurrent = searchController.isSearchEmailRunning
            ? selectionEmail.getCurrentMailboxContain(mailboxDashBoardController.mapMailboxById)
            : currentMailbox;
        if (mailboxContainCurrent != null) {
          moveSelectedMultipleEmailToSpam(selectionEmail, mailboxContainCurrent);
        }
        break;
      case EmailActionType.unSpam:
        cancelSelectEmail();
        unSpamSelectedMultipleEmail(selectionEmail);
        break;
      default:
        break;
    }
  }

  void pressEmailAction(
      BuildContext context,
      EmailActionType actionType,
      PresentationEmail selectedEmail,
      {PresentationMailbox? mailboxContain}
  ) {
    switch(actionType) {
      case EmailActionType.preview:
        if (mailboxContain?.isDrafts == true) {
          editEmail(selectedEmail);
        } else {
          previewEmail(context, selectedEmail);
        }
        break;
      case EmailActionType.selection:
        selectEmail(context, selectedEmail);
        break;
      case EmailActionType.markAsRead:
        markAsEmailRead(selectedEmail, ReadActions.markAsRead);
        break;
      case EmailActionType.markAsUnread:
        markAsEmailRead(selectedEmail, ReadActions.markAsUnread);
        break;
      case EmailActionType.markAsStarred:
        markAsStarEmail(selectedEmail, MarkStarAction.markStar);
        break;
      case EmailActionType.unMarkAsStarred:
        markAsStarEmail(selectedEmail, MarkStarAction.unMarkStar);
        break;
      case EmailActionType.moveToMailbox:
        moveToMailbox(context, selectedEmail);
        break;
      case EmailActionType.moveToTrash:
        moveToTrash(selectedEmail);
        break;
      case EmailActionType.deletePermanently:
        deleteEmailPermanently(context, selectedEmail);
        break;
      case EmailActionType.moveToSpam:
        popBack();
        moveToSpam(selectedEmail);
        break;
      case EmailActionType.unSpam:
        popBack();
        unSpam(selectedEmail);
        break;
      default:
        break;
    }
  }

  bool get isMailboxTrash => mailboxDashBoardController.selectedMailbox.value?.isTrash == true;

  void openMailboxLeftMenu() {
    mailboxDashBoardController.openMailboxMenuDrawer();
  }

  void goToSearchView() {
    SearchEmailBindings().dependencies();
    mailboxDashBoardController.dispatchRoute(DashboardRoutes.searchEmail);
  }

  void calculateDragValue(PresentationEmail? currentPresentationEmail) {
    if(currentPresentationEmail != null) {
      if(mailboxDashBoardController.listEmailSelected.contains(currentPresentationEmail)){
        listEmailDrag.clear();
        listEmailDrag.addAll(mailboxDashBoardController.listEmailSelected);
      } else {
        listEmailDrag.clear();
        listEmailDrag.add(currentPresentationEmail);
      }
    }
  }

  KeyEventResult handleKeyEvent(FocusNode node, RawKeyEvent event) {
    final shiftEvent = event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight;
    if (event is RawKeyDownEvent && shiftEvent) {
      _rangeSelectionMode = true;
    }

    if (event is RawKeyUpEvent && shiftEvent) {
      _rangeSelectionMode = false;
    }
    return shiftEvent
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  void _openEmailDetailedView(EmailId emailId) {
    if (_accountId != null) {
      consumeState(_getEmailByIdInteractor.execute(
        _accountId!,
        emailId,
        properties: ThreadConstants.propertiesDefault));
    }
  }
}