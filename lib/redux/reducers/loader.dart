import 'package:playfantasy/redux/models/loader_model.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';

LoaderModel showLoader(LoaderModel prev, action) {
  if (action is LoaderShowAction) {
    return LoaderModel(isLoading: true);
  } else if (action is LoaderHideAction) {
    return LoaderModel(isLoading: false);
  }
  return LoaderModel(isLoading: false);
}
