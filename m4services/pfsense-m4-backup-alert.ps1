# Definir variáveis
$targetFolder = "C:\BACKUP\SERVIDORESINTERNET"
$logFile = "C:\BKP\bkp_srvnet.log"
$emailReceiver = "YOUR-USER-EMAIL"
$emailSubject = "YOUR-SUBJECT"
$smtpServer = "YOUR-SMTPSERVER"
$fromEmail = "YOUR-USER-EMAIL"
$smtpUser = "YOUR-USER-EMAIL"
$smtpPass = "YOUR-EMAIL-PASS"

# Emojis para status
$statusOk = "🟢"  # Bolinha verde
$statusNegative = "🔴"  # Bolinha vermelha

# URLs das imagens
$pfsenseLogoUrl = "https://www.conexti.com.br/wp-content/uploads/2021/01/pfsense_logo.png"
$m4servicesLogoUrl = "https://m4services.com.br/logom4-black2.png"

# Apaga arquivo temporário anterior, se existir
$tempFile = [System.IO.Path]::GetTempFileName()

# Adiciona data e hora atual ao log
Add-Content -Path $logFile -Value ("[{0}] Iniciando verificação de arquivos" -f (Get-Date))

# Verifica todos os arquivos na pasta, excluindo pfSenseBackup.exe e pfSenseBackup.exe.config
$files = Get-ChildItem -Path $targetFolder | 
    Where-Object { $_.Name -notin @("pfSenseBackup.exe", "pfSenseBackup.exe.config") } | 
    Sort-Object Name

# Adiciona informações simplificadas ao log
$cutoffDate = (Get-Date).AddDays(-2)
$hasRedBalls = ($files | Where-Object { $_.LastWriteTime -lt $cutoffDate }).Count -gt 0

if ($files.Count -eq 0) {
    Add-Content -Path $logFile -Value ("[{0}] Erro: Não foram encontrados arquivos na pasta." -f (Get-Date))
} elseif ($hasRedBalls) {
    Add-Content -Path $logFile -Value ("[{0}] Erro: Alguns backups não foram concluídos com sucesso." -f (Get-Date))
} else {
    Add-Content -Path $logFile -Value ("[{0}] Sucesso: Todos os backups foram executados com sucesso." -f (Get-Date))
}

# Gera o corpo do e-mail
function Generate-EmailBody {
    $currentDate = Get-Date
    $cutoffDate = $currentDate.AddDays(-2)
    $hasRedBalls = ($files | Where-Object { $_.LastWriteTime -lt $cutoffDate }).Count -gt 0

    # Cria o conteúdo informativo
    $totalFilesCount = $files.Count
    $statusMessage = if ($hasRedBalls) {
        "Os backups não foram 100% concluídos."
    } else {
        "Todos os backups foram executados com sucesso."
    }
    $messageFooter = "$statusMessage<br>Total de arquivos encontrados: $totalFilesCount"

    # Cria a tabela HTML com todos os arquivos encontrados
    $fileDetailsHtml = if ($files.Count -gt 0) {
        $files | ForEach-Object {
            $status = if ($_.LastWriteTime -lt $cutoffDate) { 
                $statusNegative 
            } else { 
                $statusOk 
            }
            "<tr><td>$status</td><td>$($_.Name)</td><td>$($_.LastWriteTime.ToString('dd-MM-yyyy | HH:mm:ss'))</td></tr>"
        } | Out-String
    } else {
        "<tr><td colspan='3' style='text-align: center;'>Não foram encontrados arquivos na pasta.</td></tr>"
    }

    @"
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; }
        h2 { color: #2c3e50; text-align: center; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .header { text-align: center; margin-bottom: 20px; }
        .header img { max-width: 150px; margin: 0 10px; }
        .info { text-align: center; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <img src="$pfsenseLogoUrl" alt="pfSense Logo"/>
        <img src="$m4servicesLogoUrl" alt="M4 Services Logo"/>
    </div>
    <div class="info">
        <h2>Relatório de Backup</h2>
        <p>$messageFooter</p>
    </div>
    <table>
        <tr>
            <th>Status</th>
            <th>Nome do Arquivo</th>
            <th>Data e Hora</th>
        </tr>
        $fileDetailsHtml
    </table>
</body>
</html>
"@
}

# Função para enviar e-mail com o resultado
function Send-Email {
    $SmtpServer = $smtpServer
    $SmtpFrom = $fromEmail
    $SmtpTo = $emailReceiver
    $MessageSubject = $emailSubject
    $MessageBody = Generate-EmailBody

    # Configurar credenciais para o envio de e-mail
    $SmtpUsername = $smtpUser
    $SmtpPassword = ConvertTo-SecureString $smtpPass -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($SmtpUsername, $SmtpPassword)

    # Enviar o e-mail com codificação UTF-8 para o corpo
    $mailMessage = New-Object system.net.mail.mailmessage
    $mailMessage.From = $SmtpFrom
    $mailMessage.To.Add($SmtpTo)
    $mailMessage.Subject = $MessageSubject
    $mailMessage.Body = $MessageBody
    $mailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
    $mailMessage.IsBodyHtml = $true

    $smtpClient = New-Object system.net.mail.smtpclient($SmtpServer)
    $smtpClient.Credentials = $Credential
    $smtpClient.EnableSsl = $true
    $smtpClient.Send($mailMessage)
}

# Enviar o e-mail
Send-Email

# Limpa o arquivo temporário
Remove-Item $tempFile
