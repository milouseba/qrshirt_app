echo "Renommage de la branche locale 'main' en 'master'..."
git branch -m main master

echo "Suppression de 'main' sur le dépôt distant..."
git push origin :main

echo "Poussée de 'master' sur le dépôt distant..."
git push origin master

echo "Mise à jour du upstream..."
git push --set-upstream origin master

echo "✅ Terminé !"
echo "⚠️ N'oublie pas d'aller sur GitHub pour changer la branche par défaut dans Settings -> Branches !"

