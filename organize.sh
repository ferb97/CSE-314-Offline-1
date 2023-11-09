#!/bin/bash

args_count=$#
verbose_flag=0
noexecute_flag=0

wrongarguments()
{
    echo "Usage:"
    echo "./organize.sh <submission folder> <target folder> <test folder> <answer folder> [-v] [-noexecute]"
    echo
    echo "-v: verbose"
    echo "-noexecute: do not execute code files"
    echo
    exit 1
}

if [ $args_count -lt 4 ] || [ $args_count -gt 6 ]
then
    wrongarguments 

elif [ $args_count -eq 5 ]
then
    if [ "$5" = "-v" ]
    then
        verbose_flag=1

    elif [ "$5" = "-noexecute" ]
    then
        noexecute_flag=1

    else
        wrongarguments    
    fi

elif [ $args_count -eq 6 ]
then
    if [ "$5" = "-v" ]
    then
        verbose_flag=1
    else
        wrongarguments
    fi

    if [ "$6" = "-noexecute" ]
    then
        noexecute_flag=1
    else
        wrongarguments
    fi                    
fi    

submissions_path="$1"
targets_path="$2"
tests_path="$3"
answers_path="$4"

mkdir -p "$targets_path"
cd "$targets_path"

mkdir -p C
mkdir -p Python
mkdir -p Java

if [ $noexecute_flag -eq 0 ]
then
    csv_filepath="result.csv"
    touch "$csv_filepath"
    echo "student_id,type,matched,not_matched" >> "$csv_filepath"
fi

visit()
{
	if [ -d "$1" ]
	then
		for i in "$1"/*
		do
			visit "$i" "$2"
		done
	
	elif [ -f "$1" ]
	then
        filename1="$1"
		extension="${filename1##*.}"

        C_ext="c"
        Python_ext="py"
        Java_ext="java"
        right_answer=0
        wrong_answer=0

        if [ "$extension" = "c" ]
        then
            if [ $verbose_flag -eq 1 ]
            then
                echo "Organizing files of $2"
            fi

            dest_dir="../$targets_path/C"
            mkdir -p "$dest_dir/$2"
            cp "$1" "$dest_dir/$2/main.c"

            if [ $noexecute_flag -eq 1 ]
            then
                return
            fi

            if [ $verbose_flag -eq 1 ]
            then
                echo "Executing files of $2"
            fi

            cd "$dest_dir/$2"
            gcc -o main.out main.c
            tests_dir="../../../$tests_path"
            answers_dir="../../../$answers_path"

            for input in "$tests_dir"/*
            do
                filename2=$(basename "$input")
                test_number=${filename2:4}
                output="out$test_number"
                ./main.out < "$tests_dir/$filename2" > "$output"

                ans_file="ans$test_number"
                diff_out=$(diff "$answers_dir/$ans_file" "$output")

                if [ -n "$diff_out" ]
                then
                    wrong_answer=`expr $wrong_answer + 1`
                else
                    right_answer=`expr $right_answer + 1`
                fi        
            done

            echo ""$2",C,"$right_answer","$wrong_answer"" >> "../../$csv_filepath"
            cd "../../../$submissions_path"

        elif [ "$extension" = "py" ]
        then
            if [ $verbose_flag -eq 1 ]
            then
                echo "Organizing files of $2"
            fi

            dest_dir="../$targets_path/Python"
            mkdir "$dest_dir/$2"
            cp "$1" "$dest_dir/$2/main.py"

            if [ $noexecute_flag -eq 1 ]
            then
                return
            fi

            if [ $verbose_flag -eq 1 ]
            then
                echo "Executing files of $2"
            fi

            cd "$dest_dir/$2"
            tests_dir="../../../$tests_path"
            answers_dir="../../../$answers_path"

            for input in "$tests_dir"/*
            do
                filename2=$(basename "$input")
                test_number=${filename2:4}
                output="out$test_number"
                python3 main.py < "$tests_dir/$filename2" > "$output"

                ans_file="ans$test_number"
                diff_out=$(diff "$answers_dir/$ans_file" "$output")

                if [ -n "$diff_out" ]
                then
                    wrong_answer=`expr $wrong_answer + 1`
                else
                    right_answer=`expr $right_answer + 1`
                fi
            done

            echo ""$2",Python,"$right_answer","$wrong_answer"" >> "../../$csv_filepath"
            cd "../../../$submissions_path"

        elif [ "$extension" = "java" ]
        then
            if [ $verbose_flag -eq 1 ]
            then
                echo "Organizing files of $2"
            fi

            dest_dir="../$targets_path/Java"
            mkdir "$dest_dir/$2"
            cp "$1" "$dest_dir/$2/Main.java"

            if [ $noexecute_flag -eq 1 ]
            then
                return
            fi

            if [ $verbose_flag -eq 1 ]
            then
                echo "Executing files of $2"
            fi

            cd "$dest_dir/$2"
            javac Main.java
            tests_dir="../../../$tests_path"
            answers_dir="../../../$answers_path"

            for input in "$tests_dir"/*
            do
                filename2=$(basename "$input")
                test_number=${filename2:4}
                output="out$test_number"
                java Main < "$tests_dir/$filename2" > "$output"

                ans_file="ans$test_number"
                diff_out=$(diff "$answers_dir/$ans_file" "$output")

                if [ -n "$diff_out" ]
                then
                    wrong_answer=`expr $wrong_answer + 1`
                else
                    right_answer=`expr $right_answer + 1`
                fi
            done

            echo ""$2",Java,"$right_answer","$wrong_answer"" >> "../../$csv_filepath"
            cd "../../../$submissions_path"

        fi    
	fi
}

test_files_count=0
for file in "../$tests_path"/*
do
    if [ -f "$file" ]
    then
        filename=$(basename "$file")
        substr="${filename:0:4}"

        if [ "$substr" = "test" ]
        then
            test_files_count=`expr $test_files_count + 1`
        fi
    fi        
done

if [ $verbose_flag -eq 1 ]
then
    echo "Found $test_files_count test files"
fi

cd "../$submissions_path"
m=.zip

for file in ./*
do
    if [ -f "$file" ]
    then
        filename=$(basename "$file")
        substr="${filename: -4}"
        substr1="${filename: -11}"
        studentid="${substr1:0:7}"
        
        if [ m=substr ]
        then
            mkdir "$studentid"
            unzip -q "$filename" -d "$studentid"
            visit "$studentid" "$studentid"
        fi
    fi
done            