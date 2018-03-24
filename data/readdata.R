EVENTBLOCK <- 100
eventTypes <- c(queue=0, tcp=1, tcpstate=2, traffic=3, queuerecord=4, queueapprox=5, tcprecord=6,
                qcn=7, qcnqueue=8,tcp_sink=11,mtcp=12,energy=13)
eventKey <- list(queue=c(pkt_enqueue=0,pkt_drop=1,pkt_service=2),
                 queuerecord=c(cum_traffic=0),
                 tcp=c(TCP_RCV=0, TCP_RCV_FR_END=1, TCP_RCV_FR=2, TCP_RCV_DUP_FR=3,
                   TCP_RCV_DUP=4, tcp_rcv_3dupnofr=5, TCP_RCV_DUP_FASTXMIT=6, TCP_TIMEOUT=7),
                 tcpstate=c(TCPSTATE_CNTRL=0, TCPSTATE_SEQ=1),
                 traffic=c(PKT_ARRIVE=0, PKT_DEPART=1, PKT_CREATESEND=2, PKT_DISCARD=3, PKT_RCVDESTROY=4),
                 tcprecord=c(cwnd_cdf=0,ave_cwnd=1),
                 queueapprox=c(queue_range=0, queue_overflow=1),
                 qcn=c(QCN_SEND=0, QCN_INC=1, QCN_DEC=2, QCN_INCD=3, QCN_DECD=4),
                 qcnqueue=c(QCN_FB=0, QCN_NOFB=1),
                 tcp_sink=c(rate=0),
                 mtcp=c(change_a=0,rtt_update=1,window_update=2,rate=3),
                 energy=c(draw=0))
eventKey <- structure(lapply(seq(along=eventKey), function(i)
                             structure(eventKey[[i]] + eventTypes[names(eventKey)[i]]*EVENTBLOCK,
                                       names=tolower(names(eventKey[[i]]))) ),
                      names=names(eventKey))
events <- do.call('c', structure(eventKey,names=NULL))

parseDescription <- function(con) {
  descrip <- character()
  objnames <- character()
  while(TRUE) {
    samp <- readLines(con,n=1)
    if (samp=='# TRACE') break;
    if (length(samp)<1) {
      print('Log file ended unexpectedly, without # TRACE')
      break
      }
    if (substr(samp,1,1)=='#') {
      print(samp)
      descrip <- c(descrip,samp)
      next
      }
    if (substr(samp,1,1)==':') {
      objnames <- c(objnames,samp)
      next
      }
    print(samp)
    }
  descsp <- strsplit(descrip,"[ =]")
  simpar <- lapply(descsp, function(i) as.numeric(i[3]))
  names(simpar) <- sapply(descsp, function(i) i[2])
  objnamessp <- strsplit(objnames,"[ =]")
  objnames <- sapply(objnamessp, function(i) as.numeric(i[3]))
  names(objnames) <- sapply(objnamessp, function(i) i[2])
  list(simpar=simpar, objnames=objnames)
}

parseTrace <- function(filename, maxread=-1) {
  f <- file(filename)
  open(f, open='rb')
  # read the description
  preamble <- parseDescription(f)
  # read the trace
  numrec <- preamble$simpar$numrecords
  res <- data.frame(time=readBin(f,'double',n=numrec),
                          type=factor(readBin(f,'int',n=numrec,size=4,signed=FALSE),
                            levels=eventTypes,labels=names(eventTypes)),
                          id=factor(readBin(f,'int',n=numrec,size=4,signed=FALSE),
                            levels=preamble$objnames,labels=names(preamble$objnames)),
                          ev=factor(readBin(f,'int',n=numrec,size=4,signed=FALSE),
                            levels=events, labels=names(events)),
                          val1=readBin(f,'double',n=numrec),
                          val2=readBin(f,'double',n=numrec),
                          val3=readBin(f,'double',n=numrec))
  close(f)
  attributes(res) <- c(attributes(res),preamble$simpar)
  attr(res,'objnames') <- preamble$objnames
  attr(res,'simpar') <- preamble$simpar
  res
  }



####################################
## Read in MJH's semi-parsed log files

readMJHout <- function(basename) {
  qname <- paste(basename,'queue',sep='.')
  uname <- paste(basename,'util',sep='.')
  dname <- paste(basename,'drops',sep='.')
  qint <- read.table(qname)
  uint <- read.table(uname)
  dint <- read.table(dname)
  mjhres <- data.frame(time=qint[,1], type='queueapprox', id='queue12', ev='queue_range',
                       val1=qint[,2]*1600,val2=qint[,3]*1600,val3=qint[,4]*1600)
  mjhres <- rbind(mjhres,
                  data.frame(time=uint[,1][-1], type='queuerecord', id='queue12', ev='cum_traffic',
                             val1=dint[,1][-1],
                             val2 = cumsum((1-(uint[,2][-1]+1))*diff(uint[,1])),
                             val3 = cumsum( diff(dint[,1])*(dint[,2][-1]-1) )))
  mjhres
}
