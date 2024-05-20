import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class Plan extends HookConsumerWidget {
  final String friendId;
  final DateTime? selectedDate;

  const Plan({Key? key, required this.friendId, this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _editingDocumentId = useState<String?>(null);
    final _descriptionController = useTextEditingController();
    final _startDateTime = useState<DateTime?>(null);
    final _endDateTime = useState<DateTime?>(null);

    Stream<QuerySnapshot> getStream() {
      Query query = FirebaseFirestore.instance.collection('todo').where('friendId', isEqualTo: friendId);

      if (selectedDate != null) {
        query = query.where('startDateTime', isGreaterThanOrEqualTo: DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)).where('startDateTime', isLessThanOrEqualTo: DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59));
      }

      return query.snapshots();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('予定一覧'),
        backgroundColor: Colors.cyan[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getStream(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('予定がありません'));
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(thickness: 1),
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              DateTime startDateTime = data['startDateTime']?.toDate() ?? DateTime.now();
              DateTime endDateTime = data['endDateTime']?.toDate() ?? DateTime.now();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: _editingDocumentId.value == document.id
                      ? TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : Text(data['description'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        '${DateFormat('yyyy/MM/dd HH:mm').format(startDateTime)} 〜 ${DateFormat('yyyy/MM/dd HH:mm').format(endDateTime)}',
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (_editingDocumentId.value == document.id) {
                                // バリデーション
                                if (_startDateTime.value != null && _endDateTime.value != null && _endDateTime.value!.isBefore(_startDateTime.value!)) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('エラー'),
                                        content: Text('終了日時が開始日時より前になっています。日付を修正してください。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }

                                // 保存処理
                                FirebaseFirestore.instance.collection('todo').doc(document.id).update({
                                  'description': _descriptionController.text,
                                  'startDateTime': _startDateTime.value,
                                  'endDateTime': _endDateTime.value,
                                });
                                _editingDocumentId.value = null;
                                _descriptionController.clear();
                                _startDateTime.value = null;
                                _endDateTime.value = null;
                              } else {
                                // 編集モードに切り替え
                                _editingDocumentId.value = document.id;
                                _descriptionController.text = data['description'] ?? '';
                                _startDateTime.value = startDateTime;
                                _endDateTime.value = endDateTime;
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editingDocumentId.value == document.id ? Colors.green : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _editingDocumentId.value == document.id ? '保存' : '編集',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('削除の確認'),
                                    content: Text('本当に削除しますか？（取り消せません）'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // 削除処理
                                          FirebaseFirestore.instance.collection('todo').doc(document.id).delete();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              '削除',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_editingDocumentId.value == document.id)
                        Column(
                          children: [
                            SizedBox(height: 16),
                            Text('開始日時：'),
                            ElevatedButton(
                              onPressed: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _startDateTime.value ?? DateTime.now(),
                                  firstDate: DateTime(2000), // 過去の日付を許可するために設定
                                  lastDate: DateTime(2100), // 未来の日付を広く許可するために設定
                                );
                                if (pickedDate != null) {
                                  final TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      _startDateTime.value ?? DateTime.now(),
                                    ),
                                  );
                                  if (pickedTime != null) {
                                    _startDateTime.value = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _startDateTime.value != null ? DateFormat('yyyy/MM/dd HH:mm').format(_startDateTime.value!) : '開始日時を選択',
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('終了日時：'),
                            ElevatedButton(
                              onPressed: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _endDateTime.value ?? DateTime.now(),
                                  firstDate: DateTime(2000), // 過去の日付を許可するために設定
                                  lastDate: DateTime(2100), // 未来の日付を広く許可するために設定
                                );
                                if (pickedDate != null) {
                                  final TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      _endDateTime.value ?? DateTime.now(),
                                    ),
                                  );
                                  if (pickedTime != null) {
                                    _endDateTime.value = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _endDateTime.value != null ? DateFormat('yyyy/MM/dd HH:mm').format(_endDateTime.value!) : '終了日時を選択',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
