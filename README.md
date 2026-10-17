# Ongea

Application de messagerie Flutter en français, pensée d’abord pour Android. Le projet utilise Material 3, Riverpod, go_router et Firebase. La direction visuelle et les règles d’interface sont décrites dans [`docs/design-system.md`](docs/design-system.md).

## État actuel

Les parcours opérationnels comprennent l’authentification par e-mail et Google, les discussions directes, les messages texte et photos, les statuts, la recherche dans les discussions ainsi que les préférences de sourdine, d’épinglage, de favoris et d’archivage. Les photos de profil et de statut nécessitent Cloudinary; les messages et photos des discussions nécessitent Firebase. Les commandes d’appel audio/vidéo, de message vocal, de recherche dans une conversation, d’envoi de documents et les réglages non implémentés sont volontairement absents de l’interface. Le blocage et le signalement ne sont pas exposés tant que leur parcours complet de gestion n’est pas disponible.

Sans configuration Firebase, l’écran de connexion propose un mode démo en lecture seule, séparé des comptes et documents réels. Il permet de parcourir des conversations et statuts d’exemple; l’envoi, la création de conversations et la publication y sont désactivés. Les valeurs Firebase conservées dans Git sont des espaces réservés; la compilation connectée restaure la configuration depuis les secrets GitHub.

## Prérequis

- Flutter stable **3.29 ou supérieur** (Dart 3.7 ou supérieur).
- Android Studio/SDK et un appareil ou émulateur Android pour l’exécution locale.
- Firebase CLI uniquement pour déployer les règles ou fonctions.

## Démarrage en mode démo

```bash
flutter pub get
flutter run
```

Ouvrez l’écran de connexion et choisissez **Explorer la démo**. Les exemples sont locaux au mode démo; ne les confondez pas avec des données Firebase.

## Configuration Firebase locale

1. Créez ou sélectionnez le projet Firebase et enregistrez une application Android dont le nom de paquet est `com.ongea.app`.
2. Activez les fournisseurs **E-mail/Mot de passe** et **Google** dans Firebase Authentication. Créez Firestore et Storage.
3. Téléchargez le `google-services.json` de cette application dans `android/app/`.
4. Avec FlutterFire CLI, générez les options Android dans `lib/firebase_options.g.dart`. Ne remplacez pas le fichier façade `lib/firebase_options.dart`.
5. Ajoutez l’empreinte SHA-1 et SHA-256 de la clé Android utilisée dans les paramètres Firebase et du client OAuth Google. Le workflow de build affiche les empreintes du certificat réellement utilisé.
6. Déployez les règles et index depuis la racine du dépôt :

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

Le fichier `google-services.json` est ignoré par Git. Ne versionnez aucun fichier de compte de service, mot de passe ou clé de signature. Les clés API Firebase côté application ne remplacent jamais les règles de sécurité Firestore/Storage.

## Médias Cloudinary

Pour les photos de profil et de statut, créez un preset d’envoi **Unsigned** et fournissez le nom du cloud et le preset. En local, les valeurs peuvent être passées avec les définitions Dart utilisées par le workflow :

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=VOTRE_CLOUD \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=VOTRE_PRESET
```

**N’ajoutez jamais l’API Secret Cloudinary** dans l’application, un fichier du dépôt ou les secrets de build mobile.

## GitHub Actions : APK signé et release

Les workflows sont déclenchés **manuellement** depuis l’onglet **Actions**.

### Clé de signature (à créer une seule fois)

1. Ajoutez le secret de dépôt `GH_PAT`, avec l’autorisation de gérer les secrets Actions du dépôt.
2. Lancez **Générer la clé de signature (une seule fois)**. Le workflow crée et enregistre `ANDROID_KEYSTORE_B64` et `ANDROID_KEYSTORE_PASSWORD`, puis affiche les empreintes du certificat.
3. Conservez cette clé pour toutes les versions. **Ne relancez pas le workflow avec l’option d’écrasement** : une nouvelle clé empêcherait la mise à jour des installations signées avec l’ancienne.

Le workflow **Build APK Android** restaure cette clé avant la compilation et échoue si l’un des deux secrets manque. Les fichiers temporaires `android/key.properties` et `android/app/ongea-release.jks` ne sont jamais committés.

### Configuration Firebase CI (facultative, par paire)

Pour produire un APK connecté à Firebase, ajoutez les deux secrets suivants :

- `FIREBASE_OPTIONS_B64` : contenu Base64 de `lib/firebase_options.g.dart` généré pour la bonne application Android.
- `GOOGLE_SERVICES_B64` : contenu Base64 du `google-services.json` correspondant au même projet et au paquet `com.ongea.app`.

Exemple sous Linux pour afficher les valeurs à copier dans les secrets GitHub :

```bash
base64 -w0 lib/firebase_options.g.dart; echo
base64 -w0 android/app/google-services.json; echo
```

Ajoutez **les deux ou aucun** : le workflow refuse une configuration partielle. Sans les deux, le fichier d’options reste sur ses espaces réservés et l’APK démarre en mode démo. Vérifiez que les empreintes SHA enregistrées dans Firebase correspondent à la clé fixe de release, et non à la clé de débogage.

Les secrets Cloudinary optionnels sont `CLOUDINARY_CLOUD_NAME` et `CLOUDINARY_UPLOAD_PRESET`. Aucun secret de compte de service Firebase ni secret API Cloudinary ne doit être ajouté.

### Compiler / publier

Dans **Build APK Android**, choisissez `Run workflow`. L’APK signé est fourni comme artefact. Pour publier également une release, activez `publish_release` et indiquez un tag, par exemple `v1.0.0`. Le workflow attache l’APK à la release GitHub. L’étape finale affiche les empreintes SHA-1 et SHA-256 à vérifier côté Firebase.

## Vérifications

Avec le SDK Flutter installé :

```bash
flutter analyze
flutter test
```

La compilation Android release est prévue via le workflow manuel GitHub Actions; elle vérifie aussi la signature effective de l’APK.

## Structure

- `lib/core/` : thème, navigation, modèles, services et widgets partagés.
- `lib/features/` : authentification, discussions, statuts et réglages disponibles.
- `firestore.rules`, `storage.rules`, `firestore.indexes.json` : sécurité et index Firebase.
- `functions/` : Cloud Functions. Leur déploiement et les notifications sont indépendants du build mobile; les notifications sont hors du lot visuel actuel.
- `.github/workflows/` : build manuel de l’APK et création initiale de la clé.
