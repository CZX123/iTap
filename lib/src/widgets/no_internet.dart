import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InternetAvailabilityNotifier extends ValueNotifier<bool> {
  InternetAvailabilityNotifier(bool value) : super(value);
}

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final internetAvailable =
        Provider.of<InternetAvailabilityNotifier>(context).value;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: internetAvailable ? 0 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.5),
            borderRadius: BorderRadius.circular(69),
          ),
          child: Text(
            'No Internet',
            style: Theme.of(context).textTheme.body2.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
