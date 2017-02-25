<?php
    include_once 'pswd.php';

    if (isset($_GET['downloading_file'])) {
        $allowedExtentions = ',jpg,jpeg,gif,png,pdf,zip,';
        $fileUrl = $_GET['downloading_file'];
        if($fileUrl) {
            $path_parts = pathinfo($fileUrl);
            $ext = $path_parts['extension'];
            if($ext == null || strpos($allowedExtentions, ',' . strtolower($ext) . ',') === false){
                echo 'not allowed!';
                return;
            }
            $path = parse_url($fileUrl, PHP_URL_PATH);
            $filePathName = $_SERVER['DOCUMENT_ROOT'] . $path;
            $baseFileName = basename($filePathName);

   			header('Content-disposition: attachment; filename=' . $baseFileName);
            header('Content-Type: image');

            readfile($filePathName);
        }
        return;
    }

    //the following code checks the input password
    header('Content-Type: application/json');

    if(isset($_GET['get_form_text'])){
        echo '{"result":"OK", "prompt_message":"' . $formText[0] . '", "signup_message":"' . $formText[1] . '", "recovery_email":"' . $passwordRecoveryEmail . '"}';
        exit;
    }

    if(empty($_POST) || !$_POST['password']){
        echo '{"result":"failed", "description":"required information was not provided."}';
        exit;
    }

    $requestPassword = $_POST['password'];

    foreach($passwords as $pwd){
        if($pwd == $requestPassword){
            echo '{"result":"OK"}';
            exit;
        }
    }

    echo '{"result":"failed", "description":"no comment"}';

?>
