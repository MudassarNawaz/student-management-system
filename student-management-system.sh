#!/bin/bash

# Data file for storing student records
data_file="students.txt"
credentials_file="credentials.txt"
teacher_username="teacher"
teacher_password="password"

# Initialize files if they don't exist
initialize_files() {
    if [ ! -f "$data_file" ]; then
        touch "$data_file"
    fi
    
    if [ ! -f "$credentials_file" ]; then
        echo "$teacher_username:$teacher_password" > "$credentials_file"
    fi
}

# Function to calculate grade based on marks
calculate_grade() {
    marks=$1
    if (( marks >= 90 )); then echo "A+";
    elif (( marks >= 85 )); then echo "A";
    elif (( marks >= 80 )); then echo "A-";
    elif (( marks >= 75 )); then echo "B+";
    elif (( marks >= 70 )); then echo "B";
    elif (( marks >= 65 )); then echo "B-";
    elif (( marks >= 60 )); then echo "C+";
    elif (( marks >= 55 )); then echo "C";
    elif (( marks >= 50 )); then echo "C-";
    elif (( marks >= 45 )); then echo "D+";
    elif (( marks >= 40 )); then echo "D";
    else echo "F";
    fi
}

# Function to calculate grade point
calculate_grade_point() {
    case $1 in
        "A+"|"A") echo "4.00";;
        "A-") echo "3.67";;
        "B+") echo "3.33";;
        "B") echo "3.00";;
        "B-") echo "2.67";;
        "C+") echo "2.33";;
        "C") echo "2.00";;
        "C-") echo "1.67";;
        "D+") echo "1.33";;
        "D") echo "1.00";;
        *) echo "0.00";;
    esac
}

# Function to calculate CGPA for a student
calculate_student_cgpa() {
    roll=$1
    total_points=0
    count=0
    while IFS=',' read -r s_roll name marks grade gpa; do
        if [[ "$s_roll" == "$roll" ]]; then
            total_points=$(echo "$total_points + $gpa" | bc)
            count=$((count + 1))
        fi
    done < "$data_file"
    if (( count > 0 )); then
        cgpa=$(echo "scale=2; $total_points / $count" | bc)
        echo "Your CGPA: $cgpa"
    else
        echo "No records found!"
    fi
}

# Function to view student details
view_student_details() {
    echo "Enter Roll Number: "
    read -r roll
    grep "^$roll," "$data_file" || echo "Student not found!"
}

# Function to add a student
add_student() {
    # Check if we've reached the 20 student limit
    student_count=$(wc -l < "$data_file")
    if (( student_count >= 20 )); then
        echo "Maximum of 20 students reached. Cannot add more."
        return
    fi
    
    while true; do
        echo "Enter Roll Number: "
        read -r roll
        # Check if roll number already exists
        if grep -q "^$roll," "$data_file"; then
            echo "Roll number already exists. Please enter a unique roll number."
        else
            break
        fi
    done
    
    echo "Enter Name: "
    read -r name
    echo "Enter Total Marks: "
    read -r marks
    grade=$(calculate_grade "$marks")
    gpa=$(calculate_grade_point "$grade")
    echo "$roll,$name,$marks,$grade,$gpa" >> "$data_file"
    echo "Student added successfully!"
}

# Function to update student information
update_student() {
    echo "Enter Roll Number to update: "
    read -r roll
    if grep -q "^$roll," "$data_file"; then
        echo "Enter new Name (leave blank to keep current): "
        read -r new_name
        echo "Enter new Marks (leave blank to keep current): "
        read -r new_marks
        
        # Get current student data
        current_data=$(grep "^$roll," "$data_file")
        IFS=',' read -r current_roll current_name current_marks current_grade current_gpa <<< "$current_data"
        
        # Update fields if new values provided
        name=${new_name:-$current_name}
        marks=${new_marks:-$current_marks}
        
        # Recalculate grade and GPA if marks changed
        if [[ -n "$new_marks" ]]; then
            grade=$(calculate_grade "$marks")
            gpa=$(calculate_grade_point "$grade")
        else
            grade=$current_grade
            gpa=$current_gpa
        fi
        
        # Update the record
        sed -i "/^$roll,/c\\$roll,$name,$marks,$grade,$gpa" "$data_file"
        echo "Student record updated successfully!"
    else
        echo "Student not found!"
    fi
}

# Function to delete a student
delete_student() {
    echo "Enter Roll Number to Delete: "
    read -r roll
    if grep -q "^$roll," "$data_file"; then
        sed -i "/^$roll,/d" "$data_file"
        echo "Student record deleted successfully!"
    else
        echo "Student not found!"
    fi
}

# Function to generate report (all students)
generate_report() {
    echo -e "\nStudent Report:"
    echo "------------------------------------------------------------------"
    printf "%-10s %-20s %-10s %-5s %-8s\n" "Roll No" "Name" "Marks" "Grade" "GPA"
    echo "------------------------------------------------------------------"
    while IFS=',' read -r roll name marks grade gpa; do
        printf "%-10s %-20s %-10s %-5s %-8s\n" "$roll" "$name" "$marks" "$grade" "$gpa"
    done < "$data_file" | sort -k1n
    echo "------------------------------------------------------------------"
}

# Function to list students who passed (CGPA > 2.00)
list_passed_students() {
    echo -e "\nPassed Students (CGPA > 2.00):"
    echo "------------------------------------------------------------------"
    printf "%-10s %-20s %-8s\n" "Roll No" "Name" "CGPA"
    echo "------------------------------------------------------------------"
    awk -F',' '$5 > 2.00 {print $1, $2, $5}' "$data_file" | sort -k3,3nr | column -t
    echo "------------------------------------------------------------------"
}

# Function to list students who failed (CGPA ≤ 2.00)
list_failed_students() {
    echo -e "\nFailed Students (CGPA ≤ 2.00):"
    echo "------------------------------------------------------------------"
    printf "%-10s %-20s %-8s\n" "Roll No" "Name" "CGPA"
    echo "------------------------------------------------------------------"
    awk -F',' '$5 <= 2.00 {print $1, $2, $5}' "$data_file" | sort -k3,3n | column -t
    echo "------------------------------------------------------------------"
}

# Function to list students in ascending order of CGPA
list_students_ascending() {
    echo -e "\nStudents Sorted by CGPA (Ascending):"
    echo "------------------------------------------------------------------"
    printf "%-10s %-20s %-8s\n" "Roll No" "Name" "CGPA"
    echo "------------------------------------------------------------------"
    awk -F',' '{print $1, $2, $5}' "$data_file" | sort -k3,3n -t' ' | column -t
    echo "------------------------------------------------------------------"
}

# Function to list students in descending order of CGPA
list_students_descending() {
    echo -e "\nStudents Sorted by CGPA (Descending):"
    echo "------------------------------------------------------------------"
    printf "%-10s %-20s %-8s\n" "Roll No" "Name" "CGPA"
    echo "------------------------------------------------------------------"
    awk -F',' '{print $1, $2, $5}' "$data_file" | sort -k3,3nr -t' ' | column -t
    echo "------------------------------------------------------------------"
}

# Function to save data to file
save_data() {
    echo "Data is automatically saved to $data_file"
}

# Function to load data from file
load_data() {
    if [ -f "$data_file" ]; then
        echo "Data loaded from $data_file"
    else
        echo "No data file found. Starting with empty records."
    fi
}

# Function for teacher login
teacher_login() {
    echo "Enter Teacher Username: "
    read -r username
    echo "Enter Password: "
    read -rs password
    echo
    
    auth=$(grep "^$username:$password$" "$credentials_file")
    if [[ -n "$auth" ]]; then
        echo "Login Successful!"
        teacher_menu
    else
        echo "Invalid Credentials!"
    fi
}

# Teacher menu
teacher_menu() {
    while true; do
        echo -e "\nTeacher Menu"
        echo "1. Add Student (Max 20)"
        echo "2. Delete Student"
        echo "3. Update Student Information"
        echo "4. View Student Details"
        echo "5. Calculate Grades for All Students"
        echo "6. Generate Full Report"
        echo "7. List Passed Students"
        echo "8. List Failed Students"
        echo "9. List Students (Ascending CGPA)"
        echo "10. List Students (Descending CGPA)"
        echo "11. Save Data"
        echo "12. Load Data"
        echo "13. Logout"
        echo "Enter choice: "
        read -r choice
        
        case $choice in
            1) add_student ;;
            2) delete_student ;;
            3) update_student ;;
            4) view_student_details ;;
            5) calculate_grades_for_all ;;
            6) generate_report ;;
            7) list_passed_students ;;
            8) list_failed_students ;;
            9) list_students_ascending ;;
            10) list_students_descending ;;
            11) save_data ;;
            12) load_data ;;
            13) break ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# Function to calculate grades for all students
calculate_grades_for_all() {
    temp_file=$(mktemp)
    while IFS=',' read -r roll name marks grade gpa; do
        new_grade=$(calculate_grade "$marks")
        new_gpa=$(calculate_grade_point "$new_grade")
        echo "$roll,$name,$marks,$new_grade,$new_gpa" >> "$temp_file"
    done < "$data_file"
    mv "$temp_file" "$data_file"
    echo "Grades recalculated for all students."
}

# Function for student login
student_login() {
    echo "Enter Roll Number: "
    read -r roll
    student_exists=$(grep "^$roll," "$data_file")
    if [[ -n "$student_exists" ]]; then
        echo "Login Successful!"
        student_menu "$roll"
    else
        echo "Invalid Roll Number!"
    fi
}

# Student menu
student_menu() {
    roll=$1
    while true; do
        echo -e "\nStudent Menu"
        echo "1. View My Details"
        echo "2. View My Grades"
        echo "3. View My CGPA"
        echo "4. Logout"
        echo "Enter choice: "
        read -r choice
        
        case $choice in
            1) grep "^$roll," "$data_file" ;;
            2) grep "^$roll," "$data_file" | awk -F',' '{print "Grade: " $4}' ;;
            3) calculate_student_cgpa "$roll" ;;
            4) break ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# Main function
main() {
    initialize_files
    load_data
    
    while true; do
        echo -e "\nWelcome to Student Management System"
        echo "1. Teacher Login"
        echo "2. Student Login"
        echo "3. Exit"
        echo "Enter your choice: "
        read -r choice
        
        case $choice in
            1) teacher_login ;;
            2) student_login ;;
            3) 
                save_data
                echo "Goodbye!"
                exit 0
                ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# Start the program
main
