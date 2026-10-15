# Ongea — messagerie Flutter + Firebase

Application Android prioritaire en français, construite avec Flutter/Dart, Material 3, Riverpod et go_router. Firestore conserve les données de l’application, Firebase Storage les photos privées des conversations, et Cloudinary les images de statuts et les photos de profil. Les fonctions de notification déjà présentes ne sont pas requises pour le build.

> **Mode démo inclus :** lorsque Firebase n’est pas initialisé, l’application propose **Explorer la démo**. La configuration Android fournie correspond à `com.ongea.app`; activez les services souhaités dans votre projet Firebase. Cloudinary doit être configuré séparément pour les photos de statut et de profil.

## Prérequis

- Flutter stable (Dart 3.4 ou supérieur) et Android SDK ; Java 17 pour Gradle/Android. Le wrapper Gradle 8.14.3 est inclus.
- Un projet Firebase avec une application Android dont l’identifiant est `com.ongea.app`.
- Firebase CLI et Node.js 20 uniquement pour déployer les Cloud Functions.

## Étapes de réalisation

1. **Squelette, thème et navigation** — thème DM Sans/Material 3, quatre onglets, routes go_router et mode démo avec données d’exemple.
2. **Authentification** — inscription, connexion et déconnexion Firebase Auth, validation et erreurs en français.
3. **Discussions** — ouverture 1-à-1, messages temps réel, coches, non-lus, recherche/filtres, préférences et photos de conversation dans Firebase Storage.
4. **Contact et réglages** — page d’informations du contact, blocage/signalement, paramètres et profil.
5. **Actus et appels** — statuts texte/photo de 24 h ; écran Appels et liens d’appel sans moteur audio/vidéo.
6. **Notifications et hors ligne** — FCM client + Cloud Function, persistance Firestore et file d’attente hors ligne pour les messages texte.
7. **Sécurité** — règles Firestore/Storage pour les conversations, index composites et téléversement Cloudinary restreint pour les médias publics.

Le code Dart a été formaté et analysé par le parseur Dart ; la syntaxe JavaScript, les fichiers JSON et les XML Android ont aussi été vérifiés. Les tests Flutter et le build APK restent à exécuter localement après installation de Flutter/Android SDK et configuration Firebase (voir ci-dessous).

## Mise en route Firebase

1. Dans la console Firebase, créez un projet et ajoutez une application Android `com.ongea.app`.
2. Activez **Authentication → E-mail/Mot de passe**, créez une base **Cloud Firestore** et activez **Firebase Storage** pour les photos privées des conversations. Les photos de statut et de profil seront téléversées vers Cloudinary (configuration ci-dessous).
3. Installez l’outil FlutterFire puis générez les options Android. Le fichier façade `lib/firebase_options.dart` ne doit pas être écrasé :

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --out=lib/firebase_options.g.dart
   ```

   Sélectionnez le projet Firebase et Android. La commande génère/met à jour `lib/firebase_options.g.dart`. Le fichier `android/app/google-services.json` fourni a été placé dans le projet local et est ignoré par Git. Le fichier reçu correspond à `com.ongea.app`, mais sa liste de clients OAuth est vide : pour Google Sign-In, activez Google, ajoutez les empreintes SHA Android dans les paramètres Firebase, puis téléchargez à nouveau le JSON.

4. Récupérez les dépendances et déployez les règles/index :

   ```bash
   flutter pub get
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

5. Pour les notifications push et la mise à jour serveur de `lastMessage`, du statut de la dernière coche et des non-lus, déployez la fonction déclenchée à chaque message :

   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

   FCM doit être activé pour le projet. Le déploiement des Cloud Functions peut nécessiter le forfait Firebase Blaze et un compte de facturation. Sur Android 13+, Ongea demande l’autorisation de notification au premier lancement. Les jetons sont enregistrés dans `users/{uid}.fcmToken`.

6. Lancez sur un appareil ou un émulateur Android :

   ```bash
   flutter run
   ```

   Les règles refusent par défaut l’accès non authentifié. N’utilisez pas le mode test Firestore en production.

## Vérifications et APK

```bash
flutter analyze
flutter test
flutter run
flutter build apk --release
```

L’APK est généré dans `build/app/outputs/flutter-apk/app-release.apk`. La configuration Gradle fournie signe le build release avec la clé de débogage pour faciliter un essai local ; **ce n’est pas une signature de publication**. Configurez votre propre keystore avant toute diffusion publique.

### Build manuel et publication d’une release avec GitHub Actions

Le workflow `.github/workflows/android.yml` ne se lance que manuellement : dans GitHub, ouvrez **Actions → Build APK Android → Run workflow**, choisissez la branche puis lancez-le. Il affiche aussi le rapport de signature Android (`signingReport`), sans demander de compilation sur ton ordinateur. À la fin, télécharge `app-release.apk` depuis **Artifacts** (conservé 14 jours). Sans configuration Firebase, l’APK ouvre le mode démo.

Pour obtenir les empreintes à saisir dans Firebase, ouvre les journaux de cette exécution et cherche la section **`Variant: release`** du `signingReport`; copie ses lignes `SHA1` et `SHA-256`. Elles correspondent à l’APK construit dans cette même exécution. La signature actuelle est une clé de débogage du runner : pour des installations répétées ou une diffusion publique, configure une clé release stable.

Pour publier aussi une release GitHub, coche **Publier aussi une release GitHub avec l’APK** et saisis un tag, par exemple `v1.0.0`. Le workflow crée la release sur le commit sélectionné et y joint l’APK. Le job de publication utilise `GITHUB_TOKEN`; dans **Settings → Actions → General → Workflow permissions**, autorise **Read and write permissions** si le dépôt bloque l’écriture. La signature APK reste une signature de débogage et ne convient pas à Google Play.

#### Où trouver la configuration Firebase pour le build CI

1. Dans la console Firebase, ouvrez ⚙️ **Project settings → General → Your apps**. Si nécessaire, ajoutez une application Android avec l’identifiant exact `com.ongea.app`.
2. Téléchargez **`google-services.json`** depuis la fiche de cette application Android. C’est la source du secret GitHub `GOOGLE_SERVICES_B64`.
3. À la racine du projet, lancez `dart pub global activate flutterfire_cli`, puis `flutterfire configure --out=lib/firebase_options.g.dart`. Sélectionnez le même projet Firebase et l’application Android `com.ongea.app`. La commande génère `lib/firebase_options.g.dart`, source du secret `FIREBASE_OPTIONS_B64`.
4. Encodez les deux fichiers en Base64, puis copiez séparément chaque sortie dans **GitHub → dépôt → Settings → Secrets and variables → Actions → New repository secret** :

   ```bash
   base64 < lib/firebase_options.g.dart | tr -d '\n'
   base64 < android/app/google-services.json | tr -d '\n'
   ```

   Nommez les secrets exactement `FIREBASE_OPTIONS_B64` et `GOOGLE_SERVICES_B64`. Sous Windows PowerShell, produisez chaque valeur avec `[Convert]::ToBase64String([IO.File]::ReadAllBytes("chemin/vers/le/fichier"))`.

Fournissez les deux secrets Firebase ensemble, ou aucun pour le mode démo. Ce sont des configurations d’application, pas une clé de compte de service.

#### Configuration Cloudinary pour les statuts et profils

1. Créez un compte Cloudinary et relevez le **Cloud name** dans le tableau de bord.
2. Dans **Settings → Upload → Upload presets**, créez un preset de téléversement **Unsigned**. Restreignez les formats aux images utilisés (`jpg`, `jpeg`, `png`, `webp`), désactivez le choix libre du `public_id` et configurez un dossier `ongea` si l’option est disponible.
3. Dans GitHub, ouvrez le dépôt puis **Settings → Secrets and variables → Actions** et ajoutez `CLOUDINARY_CLOUD_NAME` et `CLOUDINARY_UPLOAD_PRESET` comme secrets du dépôt. L’application les reçoit au moment du build. Pour un lancement local :

   ```bash
   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=votre_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=votre_preset
   ```

N’ajoutez **jamais** le Cloudinary `API Secret` à l’application, au dépôt ou aux secrets utilisés pour le build client. Le preset unsigned est visible dans l’application et peut être réutilisé par un tiers : restreignez-le et surveillez votre consommation. La limite de 10 Mo est vérifiée par l’application, pas garantie contre un client modifié; une vérification serveur signée serait nécessaire pour une protection plus forte. Les photos de conversations restent dans Firebase Storage; les statuts et photos de profil utilisent des URL Cloudinary publiques. Les statuts expirés disparaissent du fil après 24 h, mais l’image Cloudinary ne sera pas supprimée physiquement tant qu’un nettoyage serveur sécurisé ne sera pas ajouté.

Le test widget fourni vérifie que l’application démarre sans Firebase et affiche la connexion. Parcours de vérification fonctionnelle après configuration :

1. Inscription, déconnexion puis reconnexion avec e-mail/mot de passe.
2. Création d’une discussion à partir de la liste des utilisateurs ; envoyer depuis deux appareils/émulateurs et vérifier la mise à jour temps réel.
3. Vérifier les états « envoyé », « reçu », « lu », le badge de non-lus, puis épingler, mettre en sourdine, ajouter aux favoris et archiver.
4. Envoyer une image depuis la galerie ou la caméra ; contrôler les règles Storage.
5. Publier un statut texte ou photo et vérifier qu’il disparaît après 24 h ; ouvrir un statut depuis un second compte.
6. Envoyer un message quand le destinataire est en arrière-plan et vérifier la notification push.
7. Mettre l’appareil hors ligne, envoyer un message texte puis revenir en ligne : Firestore garde la mutation locale et la synchronise automatiquement.

> L’environnement de génération ne contient pas le SDK Flutter ni l’Android SDK : `flutter analyze`, `flutter test` et `flutter build apk` n’ont donc pas pu être exécutés ici. Le code Dart a été vérifié au formatage/parseur, mais le test widget, l’analyse Flutter et le build APK doivent être lancés localement après configuration. Les fichiers Android, le test widget et les configurations sont fournis pour cela.

## Fonctionnalités et limites v1

- **Réelles avec Firebase configuré :** inscription/connexion/déconnexion, profil, discussions directes 1-à-1, messages texte en temps réel, compteur de non-lus, coches, recherche et filtres, préférences par discussion, archivage, envoi d’images, statuts texte/photo expirant après 24 h et push via Cloud Functions.
- **Hors ligne :** la persistance Firestore est activée ; les écritures texte sont conservées localement et envoyées au retour du réseau. Les photos de discussion (Firebase Storage), statuts et profils (Cloudinary) nécessitent une connexion au moment du téléversement.
- **Typographie :** DM Sans est fournie localement dans `assets/google_fonts/` (licence OFL) ; aucun téléchargement de police n’est requis.
- **Interface seulement pour cette v1 :** appels audio/vidéo et lien d’appel (aucun moteur WebRTC), messages vocaux, documents, recherche dans une conversation, messages éphémères et verrouillage local effectif. Les écrans correspondants indiquent leur disponibilité limitée.
- **Mode démo :** permet de parcourir les onglets et quelques conversations/statuts d’exemple sans compte Firebase ; les messages de démo ne sont pas persistés.

## Architecture

```text
lib/
  core/                 thème, couleurs, modèles, providers Riverpod, navigation, médias Cloudinary
  features/auth/        authentification Firebase et formulaires français
  features/chats/       liste, création 1-à-1, conversation, infos, archivage
  features/status/      publication et lecture de statuts 24 h
  features/calls/       interface de l’historique et liens d’appel
  features/settings/    paramètres et déconnexion
functions/              Cloud Functions v2 : résumé, non-lus, notifications FCM
firestore.rules         droits d’accès par utilisateur/participant
storage.rules           droits d’accès aux images
```

## Sécurité et configuration

- Aucun secret de compte de service n’est inclus. Les options Firebase client ne sont pas des secrets, mais elles doivent correspondre à votre projet.
- Firestore limite la lecture/écriture des chats et messages à leurs participants ; chaque utilisateur ne modifie que son propre profil et ses propres préférences dans une discussion. Les e-mails et jetons FCM restent dans `users/{uid}` (lecture privée) ; `profiles/{uid}` ne contient que les informations minimales nécessaires à la découverte des contacts.
- Firebase Storage vérifie la participation au chat, le type image et une limite de 10 Mo.
- Cloudinary est réservé aux photos de statut et de profil; les URL de diffusion sont publiques. Le preset unsigned doit restreindre les formats et ne jamais être remplacé par l’API Secret dans le client.
- Les signalements peuvent être créés par leur auteur uniquement ; leur lecture doit être réservée à un outil administratif hors de l’application.
- Utilisez App Check et des règles adaptées à votre politique avant une mise en production.
