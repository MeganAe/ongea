# Identité visuelle Ongea

## Direction

**Ongea** est une messagerie de proximité : chaleureuse, simple et fiable, sans ton publicitaire. L’interface parle comme une personne, en français naturel, et dit clairement ce qui fonctionne ou non. Le signe de marque est une bulle tracée à la main avec trois points corail : il évoque la parole et l’échange, sans pictogramme d’IA.

## Palette

| Rôle | Clair | Sombre |
|---|---:|---:|
| Primaire — teal profond | `#135B60` | `#82CDC2` |
| Accent — corail terre | `#C9674B` | `#F2A183` |
| Fond d’écran | `#F8FAF9` | `#101A1B` |
| Surface | `#FFFFFF` | `#152223` |
| Texte principal | `#172829` | `#E9F2F0` |
| Texte secondaire | `#586A6B` | `#A5B5B3` |
| Bordure | `#D9E3E1` | `#2C4140` |
| Bulle sortante | `#F0DDD1` | `#29413F` |
| Bulle entrante | `#FFFFFF` | `#1A2A2B` |
| Erreur | `#B43E37` | `#FF9389` |

Les couleurs sémantiques proviennent de `AppPalette`, une extension du thème Flutter. Les écrans suivent le thème clair ou sombre du système; ce lot n’ajoute pas encore de sélecteur de thème dans l’application. Aucun écran de conversation ne conserve un fond beige ou une bulle verte façon WhatsApp.

## Typographie et hiérarchie

- **DM Sans** est la police de toute l’application; ses fichiers sont embarqués, sans téléchargement réseau au démarrage.
- Titres d’écran : 20 sp, graisse 700; nom de marque : 32 sp, graisse 800.
- Texte courant : 14–16 sp; métadonnées : 12 sp au minimum lorsque l’information est importante.
- Respecter le redimensionnement système; éviter les titres entièrement en capitales et les paragraphes marketing.

## Formes, densité et icônes

- Marque : bulle de conversation dessinée, utilisée dans l’accueil et les ressources Android.
- Boutons : rayon 14 dp; champs : 15 dp; feuille modale : angles supérieurs 24 dp.
- Bulles de message : entrantes claires, sortantes teintées corail en mode clair; rayon asymétrique pour marquer le sens sans décor supplémentaire.
- Les cartes ne sont utilisées que lorsqu’elles regroupent réellement une action ou une information; ne pas enfermer chaque ligne dans une carte.
- Utiliser les variantes Material **outlined** comme famille d’icônes; réserver les variantes pleines à l’état sélectionné et aux actions principales. Les zones tactiles doivent mesurer au moins 48 dp.
- Ombres rares et discrètes. Pendant les chargements de listes, afficher des squelettes sobres et stables, annoncés aux technologies d’assistance, plutôt qu’un cercle plein écran. Les animations doivent rester courtes et fonctionnelles (environ 160–220 ms), sans dégradés violet/bleu ni effets décoratifs gratuits.

## Écrans repères

- **Connexion** : signe Ongea, titre lisible, formulaire compact uniquement lorsque Firebase est configuré, message de mode démo contrasté et explicite.
- **Discussions** : liste dense et scannable, heure et non-lus secondaires, filtres sobres; les bulles et la barre de saisie reprennent les jetons de thème.
- **Conversation** : fond neutre, distinction nette entre les deux côtés, métadonnées atténuées mais lisibles, actions principales faciles à atteindre.
- **Actus et réglages** : même palette sémantique et même hiérarchie typographique; le lecteur de statut reste une surface immersive sombre.
- **Mode démo** : indicateur visible dans les écrans parcourables, données d’exemple locales et parcours en lecture seule; les actions non disponibles sont masquées plutôt que simulées.

## Accessibilité et langue

- Contraste texte/fond vérifié à chaque changement de palette; ne pas transmettre un état uniquement par la couleur.
- Garder les cibles tactiles à 48 dp, les libellés explicites et le comportement de taille de texte du système.
- L’application et ce document sont en français. Les libellés futurs devront être centralisés dans les ressources de localisation Flutter plutôt que dupliqués dans les widgets.
