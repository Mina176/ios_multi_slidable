import 'package:flutter/material.dart';
import 'package:ios_multi_slidable/ios_multi_slidable.dart';

void main() {
  runApp(const IosMultiSlidableExample());
}

class IosMultiSlidableExample extends StatefulWidget {
  const IosMultiSlidableExample({super.key});

  @override
  State<IosMultiSlidableExample> createState() =>
      _IosMultiSlidableExampleState();
}

class _IosMultiSlidableExampleState extends State<IosMultiSlidableExample> {
  final List<String> myItems = [
    'Meeting Notes',
    'Shopping List',
    'Dinner Receipt',
    'Project Plan',
    'Vacation',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFF2F1F6),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Items',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Material(
                color: Color(0xFFF2F1F6),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.hardEdge,
                child: ListView.separated(
                  key: Key('My Items list'),
                  shrinkWrap: true,
                  itemCount: myItems.length,
                  separatorBuilder: (context, index) => Divider(height: 0.1),
                  itemBuilder: (context, index) {
                    return IosMultiSlidable(
                      tileColor: Colors.white,
                      leftActions: [
                        SlidableAction(
                          color: Color(0xFFFED500),
                          onTap: () {},
                          child: const Icon(
                            Icons.push_pin_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      rightActions: [
                        SlidableAction(
                          color: Colors.grey,
                          onTap: () {},
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        SlidableAction(
                          color: Colors.red,
                          onTap: () => setState(() => myItems.removeAt(index)),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      child: ListTile(title: Text(myItems[index])),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
