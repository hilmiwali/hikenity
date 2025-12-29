import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addParticipantCountField() async {
  final tripsCollection = FirebaseFirestore.instance.collection('trips');

  final tripsSnapshot = await tripsCollection.get();

  for (var tripDoc in tripsSnapshot.docs) {
    // Check if the 'participantCount' field already exists
    if (!tripDoc.data().containsKey('participantCount')) {
      await tripDoc.reference.update({
        'participantCount': 0,
      });
      print('Added participantCount to trip ${tripDoc.id}');
    }
  }

  print('Migration complete: All trips now have participantCount.');
}
