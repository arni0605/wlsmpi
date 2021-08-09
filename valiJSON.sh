# @Author Vasudeva Manikandan
# Purpose: Validate JSON
count=`wc -l input_v3.json | cut -d " " -f1`
echo "Count=$count"
#to_rep=`expr $count - 1`
#echo "to_rep=$to_rep"
sed "${count}s/","//" input_v3.json > input.json
checkTrue=`grep "True" input.json`
if [ $? -eq 0 ]; then
  sed -e 's/"True"/"true"/' input.json > input.json.tmp
  mv input.json.tmp input.json
fi
checkFalse=`grep "False" input.json`
if [ $? -eq 0 ]; then
  sed -e 's/"False"/"false"/' input.json > input.json.tmp
  mv input.json.tmp input.json
fi
echo "Resultant JSON as follows"
cat input.json
echo -e "\n\nPlease validate JSON here if you want  https://jsonlint.com/"

