package CloudForecast::Data::Tomcat;

use CloudForecast::Data -base;

rrds map { [ $_, 'GAUGE' ] } qw /free_memory total_memory cur_thread_count cur_thread_busy max_process_time/;
rrds map { [ $_, 'COUNTER' ] } qw /process_time requst_count error_count bytes_received bytes_sent/;

graphs 'tomcat_memory' => 'Memory (Byte)';
graphs 'tomcat_thread' => 'Thread';
graphs 'tomcat_max_processing' => 'Process time (s)';
graphs 'tomcat_processing' => 'Process time (s)';
graphs 'tomcat_count' => 'Count per Sec';
graphs 'tomcat_bytes' => 'Bytes per Sec';

title {
    my $c = shift;
    my $title = "Tomcat";
#    if ( my $port = $c->component('Tomcat')->port ) {
#        $title .= " ($port)";
#    }
    return $title;
};

sysinfo {
    my $c = shift;
    $c->ledge_get('sysinfo') || [];
};

fetcher {
    my $c = shift;
    my $tomcat = $c->component('Tomcat');
    my $ua = $c->component('LWP');
    my $content = $tomcat->set;
    my $response = $ua->request($content);
    die "Tomcat manager failed: " .$response->status_line unless $response->is_success;
    
    if ( my $server_version = $response->header('Server') ) {
      $c->ledge_set('sysinfo', [ version => $server_version ] );
    }
    
    my $tomcat_data = $response->content;
    my $free_memory;
    my $total_memory;
    my $cur_thread_count;
    my $cur_thread_busy;
    my $max_processing_time;
    my $processing_time;
    my $requst_count;
    my $error_count;
    my $bytes_received;
    my $bytes_sent;


    foreach my $line ( split /[\r\n]+/, $tomcat_data ) {
      if ( $line =~ /Free memory: (\d+\.?\d+)/ ) {
        $free_memory = int($1*1048576);
      }
      if ( $line =~ /Total memory: (\d+\.?\d+)/ ) {
        $total_memory = int($1*1048576);
      }
      if ( $line =~ /Current thread count: (\d+)/ ) {
        $cur_thread_count = $1;
      }
      if ( $line =~ /Current thread busy: (\d+)/ ) {
        $cur_thread_busy = $1;
      }
      if ( $line =~ /Max processing time: (\d+)/ ) {
        $max_processing_time = $1;
      }
      if ( $line =~ /Processing time: (\d+\.?\d+)/ ) {
        $processing_time = int($1*1000);
      }
      if ( $line =~ /Request count: (\d+)/ ) {
        $requst_count = $1;
      }
      if ( $line =~ /Error count: (\d+)/ ) {
        $error_count = $1;
      }
      if ( $line =~ /Bytes received: (\d+\.?\d+)/ ) {
        $bytes_received = int($1*1048576);
      }
      if ( $line =~ /Bytes sent: (\d+\.?\d+)/ ) {
        $bytes_sent = int($1*1048576);
      }
    }
    return [$free_memory,$total_memory,$cur_thread_count,$cur_thread_busy,$max_processing_time,$processing_time,$requst_count,$error_count,$bytes_received,$bytes_sent];
};

__DATA__
@@ tomcat_memory
DEF:my1=<%RRD%>:total_memory:AVERAGE
DEF:my2=<%RRD%>:free_memory:AVERAGE
CDEF:my3=my1,my2,-
AREA:my1#0000C0:Total Memory
GPRINT:my1:LAST:Cur\:%.1lf %s
GPRINT:my1:AVERAGE:Ave\:%.1lf %s
GPRINT:my1:MAX:Max\:%.1lf %s
GPRINT:my1:MIN:Min\:%.1lf %s\l
AREA:my3#00C000:Used Memory
GPRINT:my3:LAST:Cur\:%.1lf %s
GPRINT:my3:AVERAGE:Ave\:%.1lf %s
GPRINT:my3:MAX:Max\:%.1lf %s
GPRINT:my3:MIN:Min\:%.1lf %s\l

@@ tomcat_thread
DEF:my1=<%RRD%>:cur_thread_count:AVERAGE
DEF:my2=<%RRD%>:cur_thread_busy:AVERAGE
AREA:my1#c0c0c0:Thread Count
GPRINT:my1:LAST:Cur\:%.0lf %s
GPRINT:my1:AVERAGE:Ave\:%.0lf %s
GPRINT:my1:MAX:Max\:%.0lf %s
GPRINT:my1:MIN:Min\:%.0lf %s\l
AREA:my2#800080:Thread Busy
GPRINT:my2:LAST:Cur\:%.0lf %s
GPRINT:my2:AVERAGE:Ave\:%.0lf %s
GPRINT:my2:MAX:Max\:%.0lf %s
GPRINT:my2:MIN:Min\:%.0lf %s\l

@@ tomcat_max_processing
DEF:my1=<%RRD%>:max_process_time:AVERAGE
CDEF:my2=my1,1000,/
LINE:my2#00C000:Max One Process
GPRINT:my2:LAST:Cur\:%.1lf %s
GPRINT:my2:AVERAGE:Ave\:%.1lf %s
GPRINT:my2:MAX:Max\:%.1lf %s
GPRINT:my2:MIN:Min\:%.1lf %s\l

@@ tomcat_processing
DEF:my1=<%RRD%>:process_time:AVERAGE
CDEF:my2=my1,1000,/
AREA:my2#990000:Total per Sec
GPRINT:my2:LAST:Cur\:%.1lf %s
GPRINT:my2:AVERAGE:Ave\:%.1lf %s
GPRINT:my2:MAX:Max\:%.1lf %s
GPRINT:my2:MIN:Min\:%.1lf %s\l

@@ tomcat_count
DEF:my1=<%RRD%>:requst_count:AVERAGE
DEF:my2=<%RRD%>:error_count:AVERAGE
AREA:my1#C0C0C0:Request
GPRINT:my1:LAST:Cur\:%.0lf %s
GPRINT:my1:AVERAGE:Ave\:%.0lf %s
GPRINT:my1:MAX:Max\:%.0lf %s
GPRINT:my1:MIN:Min\:%.0lf %s\l
STACK:my2#800080:Error
GPRINT:my2:LAST:Cur\:%.0lf %s
GPRINT:my2:AVERAGE:Ave\:%.0lf %s
GPRINT:my2:MAX:Max\:%.0lf %s
GPRINT:my2:MIN:Min\:%.0lf %s\l

@@ tomcat_bytes
DEF:my1=<%RRD%>:bytes_received:AVERAGE
DEF:my2=<%RRD%>:bytes_sent:AVERAGE
AREA:my1#CCCCCC:Received
GPRINT:my1:LAST:Cur\:%.1lf %s
GPRINT:my1:AVERAGE:Ave\:%.1lf %s
GPRINT:my1:MAX:Max\:%.1lf %s
GPRINT:my1:MIN:Min\:%.1lf %s\l
STACK:my2#FFAAFF:Sent
GPRINT:my2:LAST:Cur\:%.1lf %s
GPRINT:my2:AVERAGE:Ave\:%.1lf %s
GPRINT:my2:MAX:Max\:%.1lf %s
GPRINT:my2:MIN:Min\:%.1lf %s\l

