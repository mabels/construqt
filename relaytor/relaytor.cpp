

#include <iostream>
#include <fstream>
#include <typeinfo>       // operator typeid
#include <cerrno>         // errno
#include <list>         // errno
#include <map>         // errno
#include <set>         // errno
#include <thread>         // errno
#include <system_error>
#include <exception>
#include <memory>
#include <string>
#include <vector>

#define _ELPP_NO_DEFAULT_LOG_FILE
#define _ELPP_SYSLOG
#include "easylogging++.h"
#include <syslog.h>


#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include <limits.h>
#include <net/if.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <netdb.h>
#include <getopt.h>

class RelayTorWriter : el::base::NoCopy {
  public:
    RelayTorWriter(void) {}

    // RelayTor manipulator
    inline RelayTorWriter& operator<<(std::ostream& (*)(std::ostream&)) {
      return *this;
    }

    template <typename T>
      inline RelayTorWriter& operator<<(const T&) {
        return *this;
      }
};

//#define L(level) _ELPP_WRITE_LOG(RelayTorWriter, level)
static const char *activeLoggerId = el::base::consts::kDefaultLoggerId;
static el::base::DispatchAction activeDispatchAction = el::base::DispatchAction::NormalLog;
#define L(LEVEL) C##LEVEL(el::base::Writer, activeDispatchAction, activeLoggerId)

class Formatter {
  public:
    Formatter() {}
    ~Formatter() {}

    template <typename Type> Formatter & operator << (const Type & value) {
      stream_ << value;
      return *this;
    }

    std::string str() const         { return stream_.str(); }
    operator std::string () const   { return stream_.str(); }

    enum ConvertToString {
      to_str
    };
    std::string operator >> (ConvertToString) { return stream_.str(); }

  private:
    std::stringstream stream_;

    Formatter(const Formatter &);
    Formatter & operator = (Formatter &);
};

namespace Dhcp {
  class SocketAddr {
    public:
      virtual const void *getConstBuf() const  = 0;
      virtual void *getBuf() = 0;
      virtual void assign(const SocketAddr &other) = 0;
      virtual std::string toString() const = 0;
      virtual bool isSet() const = 0;
  };
  class Relay {
    public:
      virtual size_t getIfIndex() const = 0;
      virtual const short getListenPort() const = 0;
      virtual const SocketAddr &getServerIp() const = 0;
      virtual const short getServerPort() const = 0;
      virtual const SocketAddr &getGatewayIp() const = 0;
  };

  class Header {
    public:
      virtual void *getPacket() = 0;
      virtual size_t getPacketSize() const = 0;
      virtual bool isRequest() const = 0;
      virtual bool isReply() const = 0;
      virtual bool incHops() = 0;
      virtual int getXid() const = 0;
      virtual const unsigned char *getSname() = 0;
      virtual const unsigned char *getFile() = 0;
      virtual SocketAddr &getGiaddr() = 0;
      virtual SocketAddr &getCiaddr() = 0;
      virtual SocketAddr &getYiaddr() = 0;
      virtual SocketAddr &getSiaddr() = 0;
  };

  class UdpSocket {
    public:
      const int fd;
      UdpSocket() : fd(socket(PF_INET, SOCK_DGRAM, 0)) {
        if (fd < 0) {
          throw std::system_error(std::error_code(errno,std::generic_category()), "can open socket");
        }
      }
      ~UdpSocket() {
        close(fd);
      }
  };

  namespace V4 {
    class SocketAddr : public Dhcp::SocketAddr {
      private:
        struct in_addr *addr;
        struct in_addr own;
      public:
        SocketAddr() : addr(&own) {
        }
        SocketAddr(struct in_addr *_addr) : addr(_addr) {
        }
        virtual void assign(const Dhcp::SocketAddr &other) {
          memcpy(addr, other.getConstBuf(), sizeof(*addr));
        }
        virtual const void *getConstBuf() const {
          return addr;
        }
        virtual void *getBuf() {
          return addr;
        }
        virtual std::string toString() const {
          char dst[INET_ADDRSTRLEN];
          inet_ntop(AF_INET, addr, dst, sizeof(dst));
          return dst;
        }
        virtual bool isSet() const {
          return addr->s_addr != INADDR_ANY;
        }
    };


    struct Packet {
      struct {
        unsigned char op, htype, hlen, hops;
        unsigned int xid;
        unsigned short secs, flags;
        struct in_addr ciaddr, yiaddr, siaddr, giaddr;
        unsigned char chaddr[16], sname[64], file[128];
      } header;
      unsigned char options[16384];
    };

    class Header : public Dhcp::Header {
      private:
        struct Packet packet;
        SocketAddr giAddr;
        SocketAddr yiAddr;
        SocketAddr siAddr;
        SocketAddr ciAddr;
      public:
        Header() :
          giAddr(&packet.header.giaddr),
          yiAddr(&packet.header.yiaddr),
          siAddr(&packet.header.siaddr),
          ciAddr(&packet.header.ciaddr) {
          }
        virtual ~Header() {}
        virtual void *getPacket() {
          return &packet;
        }
        virtual SocketAddr &getGiaddr() {
          return giAddr;
        }
        virtual SocketAddr &getSiaddr() {
          return siAddr;
        }
        virtual SocketAddr &getYiaddr() {
          return yiAddr;
        }
        virtual SocketAddr &getCiaddr() {
          return ciAddr;
        }
        virtual bool isRequest() const {
          return packet.header.op == 1;
        }
        virtual bool isReply() const {
          return packet.header.op == 2;
        }
        virtual bool incHops() {
          return packet.header.hops++ > 20;
        }

        virtual size_t getPacketSize() const {
          return sizeof(packet);
        }
        virtual int getXid() const {
          return packet.header.xid;
        }
        virtual const unsigned char *getSname() {
          return packet.header.sname;
        }
        virtual const unsigned char *getFile() {
          return packet.header.file;
        }
    };
  }

  namespace V6 {
    class SocketAddr : public Dhcp::SocketAddr {
      private:
        struct in6_addr *addr;
        struct in6_addr own;
      public:
        SocketAddr() : addr(&own) {
        }
        SocketAddr(struct in6_addr *_addr) : addr(_addr) {
        }
        virtual void assign(const Dhcp::SocketAddr &other) {
          memcpy(addr, other.getConstBuf(), sizeof(*addr));
        }
        virtual const void *getConstBuf() const {
          return addr;
        }
        virtual void *getBuf() {
          return addr;
        }
        virtual std::string toString() const {
          char dst[INET6_ADDRSTRLEN];
          inet_ntop(AF_INET6, addr, dst, sizeof(dst));
          return dst;
        }
        virtual bool isSet() const {
          return memcmp(&(addr->s6_addr), &IN6ADDR_ANY_INIT, sizeof(addr->s6_addr));
        }
    };


    struct Packet {
      struct {
        unsigned char op, htype, hlen, hops;
        unsigned int xid;
        unsigned short secs, flags;
        struct in6_addr ciaddr, yiaddr, siaddr, giaddr;
        unsigned char chaddr[16], sname[64], file[128];
      } header;
      unsigned char options[16384];
    };

    class Header : public Dhcp::Header {
      private:
        struct Packet packet;
        SocketAddr giAddr;
        SocketAddr yiAddr;
        SocketAddr siAddr;
        SocketAddr ciAddr;
      public:
        Header() :
          giAddr(&packet.header.giaddr),
          yiAddr(&packet.header.yiaddr),
          siAddr(&packet.header.siaddr),
          ciAddr(&packet.header.ciaddr) {
          }
        virtual ~Header() {}
        virtual void *getPacket() {
          return &packet;
        }
        virtual SocketAddr &getGiaddr() {
          return giAddr;
        }
        virtual SocketAddr &getSiaddr() {
          return siAddr;
        }
        virtual SocketAddr &getYiaddr() {
          return yiAddr;
        }
        virtual SocketAddr &getCiaddr() {
          return ciAddr;
        }
        virtual bool isRequest() const {
          return packet.header.op == 1;
        }
        virtual bool isReply() const {
          return packet.header.op == 2;
        }
        virtual bool incHops() {
          return packet.header.hops++ > 20;
        }

        virtual size_t getPacketSize() const {
          return sizeof(packet);
        }
        virtual int getXid() const {
          return packet.header.xid;
        }
        virtual const unsigned char *getSname() {
          return packet.header.sname;
        }
        virtual const unsigned char *getFile() {
          return packet.header.file;
        }
    };
  }

  class Request {
    private:
      int size = -1;
      int ifindex = -1;
      int sourcePort = -1;
      UdpSocket &socket;
      struct ifreq ifr;
      std::unique_ptr<Header> header;
    public:
      Request(Header *_header, UdpSocket& _socket) : header(_header), socket(_socket) {
      }

      void *getPacket() {
        return this->header->getPacket();
      }
      size_t getPacketSize() {
        return this->header->getPacketSize();
      }
      const char *getIfName() {
        ifr.ifr_ifindex = this->getIfIndex();
        if (ioctl(this->socket.fd, SIOCGIFNAME, &ifr) < 0) {
          throw std::system_error(std::error_code(errno,std::generic_category()),
              Formatter() << "can ioctl SIOCGIFNAME for ifr_index:" << ifr.ifr_ifindex);
        }
        return ifr.ifr_name;
      }

      short getSourcePort() const {
        return sourcePort;
      }

      void setSourcePort(int sourcePort) {
        this->sourcePort = sourcePort;
      }

      void setSize(int size) {
        this->size = size;
      }

      void setIfIndex(int ifindex) {
        this->ifindex = ifindex;
      }

      int getSize() const {
        return this->size;
      }

      size_t getIfIndex() const {
        return this->ifindex;
      }
      Header &getHeader() {
        return *(this->header);
      }

  };

  class PacketSource {
    public:
      virtual std::list<std::unique_ptr<Relay>>& Relays() = 0;
      virtual std::unique_ptr<Request> Recv() = 0;
      virtual void Send(Request &request, const SocketAddr &serverIp, const short serverPort) = 0;
      virtual void Start() = 0;
      virtual void Stop() = 0;
  };


  namespace Linux {

    namespace V4 {
      class Relay : public Dhcp::Relay {
        private:
          short listenPort;
          Dhcp::V4::SocketAddr serverIp;
          short serverPort;
          Dhcp::V4::SocketAddr gatewayIp;
          size_t ifIndex = 0;
          struct in_addr inIfaceSrcAddr;
        public:
          virtual ~Relay() { }
          virtual size_t getIfIndex() const {
            return ifIndex;
          }
          virtual const short getListenPort() const {
            return listenPort;
          }
          virtual const short getServerPort() const {
            return serverPort;
          }
          virtual const Dhcp::SocketAddr &getGatewayIp() const {
            return gatewayIp;
          }
          virtual const Dhcp::SocketAddr &getServerIp() const {
            return serverIp;
          }
          Relay(const char *inIface, short listenPort, const char *serverIp, short serverPort, const char *gatewayIp) {
            const UdpSocket socket;
            this->listenPort = listenPort;
            this->serverPort = serverPort;
            if (inet_pton(AF_INET, serverIp, this->serverIp.getBuf()) <= 0) {
              throw std::invalid_argument(Formatter() << "can not parse address:" << serverIp);
            }
            if (inet_pton(AF_INET, gatewayIp, this->gatewayIp.getBuf()) <= 0) {
              throw std::invalid_argument(Formatter() << "can not parse address:" << gatewayIp);
            }
            struct ifreq ifr;
            ifr.ifr_addr.sa_family = AF_INET;
            //bool found = false;
            for(int idx = 1; true ; ++idx) {
              ifr.ifr_ifindex = idx;
              //L(DEBUG) << "ifidx=" << ifr.ifr_ifindex << ":" << sizeof(ifr.ifr_addr.sa_family);
              if (ioctl(socket.fd, SIOCGIFNAME, &ifr) < 0) {
                if (errno != ENODEV) {
                  throw std::invalid_argument(Formatter() << "can get interfaces name of idx:" << idx);
                }
                break;
              }
              //L(DEBUG) << ifr.ifr_name;
              //L(DEBUG) << inIface;
              //L(DEBUG) << sizeof(ifr.ifr_name);
              //L(DEBUG) << "cmp=" <<strncmp(inIface, ifr.ifr_name, sizeof(ifr.ifr_name));
              //L(DEBUG) << "idx=" <<ifIndex;
              if (!strncmp(inIface, ifr.ifr_name, sizeof(ifr.ifr_name)) && ifIndex == 0) {
                if (ioctl (socket.fd, SIOCGIFADDR, &ifr) < 0) {
                  throw std::invalid_argument(Formatter() << "can get interfaces address:" << ifr.ifr_name);
                }
                /*
                   if (ioctl (socket.fd, SIOCGIFFLAGS, &ifr) < 0 || !(ifr.ifr_flags & IFF_BROADCAST)) {
                   throw std::invalid_argument(Formatter() << "listenIf is not a broadcast device:" << ifr.ifr_name);
                   }
                   */
                inIfaceSrcAddr = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;
                ifIndex = idx;
                //found = true;
                return;
              }
            }
            //if (!found) {
            throw std::invalid_argument(Formatter() << "Interface not found:" << inIface);
            //}
          }
      };


      class PacketSource : public Dhcp::PacketSource {
        private:
          std::list<std::unique_ptr<Dhcp::Relay>> relays;
          UdpSocket sock;
        public:
          void addRelay(const char *inIface, short listenPort, const char *serverIp, const short serverPort, const char *gatewayIp) {
            relays.push_back(std::unique_ptr<Dhcp::Relay>(new Relay(inIface, listenPort, serverIp, serverPort, gatewayIp)));
          }
          virtual std::list<std::unique_ptr<Dhcp::Relay>>& Relays() {
            return relays;
          }


          virtual void Start() {
            const int oneopt = 1;
            if (setsockopt(sock.fd, SOL_IP, IP_PKTINFO, &oneopt, sizeof(oneopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_PKTINFO");
            }
            if (setsockopt(sock.fd, SOL_SOCKET, SO_BROADCAST, &oneopt, sizeof(oneopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_SOCKET, SO_BROADCAST");
            }
            const int mtuopt = IP_PMTUDISC_DONT;
            if (setsockopt(sock.fd, SOL_IP, IP_MTU_DISCOVER, &mtuopt, sizeof(mtuopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_MTU_DISCOVER");
            }
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            saddr.sin_port = htons(relays.front()->getListenPort());
            saddr.sin_addr.s_addr = INADDR_ANY;
            if (bind(sock.fd, (struct sockaddr *)&saddr, sizeof(struct sockaddr_in))) {
              throw std::system_error(std::error_code(errno,std::generic_category()), Formatter() << "can bind udp port:" << relays.front()->getListenPort());
            }
          }

          virtual void Send(Request &request, const SocketAddr &serverIp, const short port) {
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            memcpy(&saddr.sin_addr, serverIp.getConstBuf(), sizeof(saddr.sin_addr));
            saddr.sin_port = htons(port);
            //L(DEBUG) << "s:addr=" << serverIp.toString() << ":port=" << port << ":xid=" << request.getHeader().getXid()
            //<< ":ciaddr=" << request.getHeader().getCiaddr().toString() << ":yiaddr=" << request.getHeader().getYiaddr().toString()
            //<< ":siaddr=" << request.getHeader().getSiaddr().toString() << ":giaddr=" << request.getHeader().getGiaddr().toString();
            if (sendto(sock.fd, request.getPacket(), request.getSize(), 0, (struct sockaddr *)&saddr, sizeof(saddr)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), Formatter() << "can sendto:" << serverIp.toString() << ":" << port);
            }
          }

          virtual std::unique_ptr<Request> Recv() {
            std::unique_ptr<Request> request(new Request(new Dhcp::V4::Header(), sock));
            struct sockaddr_in saddr;
            Dhcp::V4::SocketAddr _saddr(&saddr.sin_addr);
            struct msghdr msg;
            struct iovec iov;
            union {
              struct cmsghdr align; /* this ensures alignment */
              char control[CMSG_SPACE(sizeof(struct in_pktinfo))];
            } control_u;

            msg.msg_control = control_u.control;
            msg.msg_controllen = sizeof(control_u);
            msg.msg_name = &saddr;
            msg.msg_namelen = sizeof(saddr);
            msg.msg_iov = &iov;
            msg.msg_iovlen = 1;
            iov.iov_base = request->getPacket();
            iov.iov_len = request->getPacketSize();

            int size = recvmsg(this->sock.fd, &msg, 0);
            if (size < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "recvmsg failed");
            }
            for (struct cmsghdr *cmptr = CMSG_FIRSTHDR(&msg); cmptr; cmptr = CMSG_NXTHDR(&msg, cmptr)) {
              if (cmptr->cmsg_level == SOL_IP && cmptr->cmsg_type == IP_PKTINFO) {
                union {
                  unsigned char *c;
                  struct in_pktinfo *p;
                } p;
                p.c = CMSG_DATA(cmptr);
                request->setIfIndex(p.p->ipi_ifindex);
                request->setSize(size);
                request->setSourcePort(ntohs(saddr.sin_port));
                //L(DEBUG) << "r:Size:" << request->getSize() << ":Addr=" << _saddr.toString() << ":" << ntohs(saddr.sin_port)
                //<< ":ifidx=" << request->getIfIndex() << ":name=" << request->getIfName()
                //<< ":xid=" << request->getHeader().getXid() << ":ciaddr=" << request->getHeader().getCiaddr().toString()
                //<< ":yiaddr=" << request->getHeader().getYiaddr().toString() << ":siaddr=" << request->getHeader().getSiaddr().toString()
                //<< ":giaddr=" << request->getHeader().getGiaddr().toString();
                return request;
              }
            }
            throw std::invalid_argument("no interface found in received packet");
          }
          virtual void Stop() { }
      };
    }
    namespace V6 {
      class Relay : public Dhcp::Relay {
        private:
          short listenPort;
          Dhcp::V6::SocketAddr serverIp;
          short serverPort;
          Dhcp::V6::SocketAddr gatewayIp;
          size_t ifIndex = 0;
          struct in_addr inIfaceSrcAddr;
        public:
          virtual ~Relay() { }
          virtual size_t getIfIndex() const {
            return ifIndex;
          }
          virtual const short getListenPort() const {
            return listenPort;
          }
          virtual const short getServerPort() const {
            return serverPort;
          }
          virtual const Dhcp::SocketAddr &getGatewayIp() const {
            return gatewayIp;
          }
          virtual const Dhcp::SocketAddr &getServerIp() const {
            return serverIp;
          }
          Relay(const char *inIface, short listenPort, const char *serverIp, short serverPort, const char *gatewayIp) {
            const UdpSocket socket;
            this->listenPort = listenPort;
            this->serverPort = serverPort;
            if (inet_pton(AF_INET, serverIp, this->serverIp.getBuf()) <= 0) {
              throw std::invalid_argument(Formatter() << "can not parse address:" << serverIp);
            }
            if (inet_pton(AF_INET, gatewayIp, this->gatewayIp.getBuf()) <= 0) {
              throw std::invalid_argument(Formatter() << "can not parse address:" << gatewayIp);
            }
            struct ifreq ifr;
            ifr.ifr_addr.sa_family = AF_INET;
            //bool found = false;
            for(int idx = 1; true ; ++idx) {
              ifr.ifr_ifindex = idx;
              //L(DEBUG) << "ifidx=" << ifr.ifr_ifindex << ":" << sizeof(ifr.ifr_addr.sa_family);
              if (ioctl(socket.fd, SIOCGIFNAME, &ifr) < 0) {
                if (errno != ENODEV) {
                  throw std::invalid_argument(Formatter() << "can get interfaces name of idx:" << idx);
                }
                break;
              }
              //L(DEBUG) << ifr.ifr_name;
              //L(DEBUG) << inIface;
              //L(DEBUG) << sizeof(ifr.ifr_name);
              //L(DEBUG) << "cmp=" <<strncmp(inIface, ifr.ifr_name, sizeof(ifr.ifr_name));
              //L(DEBUG) << "idx=" <<ifIndex;
              if (!strncmp(inIface, ifr.ifr_name, sizeof(ifr.ifr_name)) && ifIndex == 0) {
                if (ioctl (socket.fd, SIOCGIFADDR, &ifr) < 0) {
                  throw std::invalid_argument(Formatter() << "can get interfaces address:" << ifr.ifr_name);
                }
                /*
                   if (ioctl (socket.fd, SIOCGIFFLAGS, &ifr) < 0 || !(ifr.ifr_flags & IFF_BROADCAST)) {
                   throw std::invalid_argument(Formatter() << "listenIf is not a broadcast device:" << ifr.ifr_name);
                   }
                   */
                inIfaceSrcAddr = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;
                ifIndex = idx;
                //found = true;
                return;
              }
            }
            //if (!found) {
            throw std::invalid_argument(Formatter() << "Interface not found:" << inIface);
            //}
          }
      };


      class PacketSource : public Dhcp::PacketSource {
        private:
          std::list<std::unique_ptr<Dhcp::Relay>> relays;
          UdpSocket sock;
        public:
          void addRelay(const char *inIface, short listenPort, const char *serverIp, const short serverPort, const char *gatewayIp) {
            relays.push_back(std::unique_ptr<Dhcp::Relay>(new Relay(inIface, listenPort, serverIp, serverPort, gatewayIp)));
          }
          virtual std::list<std::unique_ptr<Dhcp::Relay>>& Relays() {
            return relays;
          }


          virtual void Start() {
            const int oneopt = 1;
            if (setsockopt(sock.fd, SOL_IP, IP_PKTINFO, &oneopt, sizeof(oneopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_PKTINFO");
            }
            if (setsockopt(sock.fd, SOL_SOCKET, SO_BROADCAST, &oneopt, sizeof(oneopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_SOCKET, SO_BROADCAST");
            }
            const int mtuopt = IP_PMTUDISC_DONT;
            if (setsockopt(sock.fd, SOL_IP, IP_MTU_DISCOVER, &mtuopt, sizeof(mtuopt)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_MTU_DISCOVER");
            }
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            saddr.sin_port = htons(relays.front()->getListenPort());
            saddr.sin_addr.s_addr = INADDR_ANY;
            if (bind(sock.fd, (struct sockaddr *)&saddr, sizeof(struct sockaddr_in))) {
              throw std::system_error(std::error_code(errno,std::generic_category()), Formatter() << "can bind udp port:" << relays.front()->getListenPort());
            }
          }

          virtual void Send(Request &request, const SocketAddr &serverIp, const short port) {
            struct sockaddr_in saddr;
            saddr.sin_family = AF_INET;
            memcpy(&saddr.sin_addr, serverIp.getConstBuf(), sizeof(saddr.sin_addr));
            saddr.sin_port = htons(port);
            //L(DEBUG) << "s:addr=" << serverIp.toString() << ":port=" << port << ":xid=" << request.getHeader().getXid()
            //<< ":ciaddr=" << request.getHeader().getCiaddr().toString() << ":yiaddr=" << request.getHeader().getYiaddr().toString()
            //<< ":siaddr=" << request.getHeader().getSiaddr().toString() << ":giaddr=" << request.getHeader().getGiaddr().toString();
            if (sendto(sock.fd, request.getPacket(), request.getSize(), 0, (struct sockaddr *)&saddr, sizeof(saddr)) < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), Formatter() << "can sendto:" << serverIp.toString() << ":" << port);
            }
          }

          virtual std::unique_ptr<Request> Recv() {
            std::unique_ptr<Request> request(new Request(new Dhcp::V6::Header(), sock));
            struct sockaddr6_in saddr;
            V6::SocketAddr _saddr(&saddr.sin_addr);
            struct msghdr msg;
            struct iovec iov;
            union {
              struct cmsghdr align; /* this ensures alignment */
              char control[CMSG_SPACE(sizeof(struct in_pktinfo))];
            } control_u;

            msg.msg_control = control_u.control;
            msg.msg_controllen = sizeof(control_u);
            msg.msg_name = &saddr;
            msg.msg_namelen = sizeof(saddr);
            msg.msg_iov = &iov;
            msg.msg_iovlen = 1;
            iov.iov_base = request->getPacket();
            iov.iov_len = request->getPacketSize();

            int size = recvmsg(this->sock.fd, &msg, 0);
            if (size < 0) {
              throw std::system_error(std::error_code(errno,std::generic_category()), "recvmsg failed");
            }
            for (struct cmsghdr *cmptr = CMSG_FIRSTHDR(&msg); cmptr; cmptr = CMSG_NXTHDR(&msg, cmptr)) {
              if (cmptr->cmsg_level == SOL_IP && cmptr->cmsg_type == IP_PKTINFO) {
                union {
                  unsigned char *c;
                  struct in_pktinfo *p;
                } p;
                p.c = CMSG_DATA(cmptr);
                request->setIfIndex(p.p->ipi_ifindex);
                request->setSize(size);
                request->setSourcePort(ntohs(saddr.sin_port));
                //L(DEBUG) << "r:Size:" << request->getSize() << ":Addr=" << _saddr.toString() << ":" << ntohs(saddr.sin_port)
                //<< ":ifidx=" << request->getIfIndex() << ":name=" << request->getIfName()
                //<< ":xid=" << request->getHeader().getXid() << ":ciaddr=" << request->getHeader().getCiaddr().toString()
                //<< ":yiaddr=" << request->getHeader().getYiaddr().toString() << ":siaddr=" << request->getHeader().getSiaddr().toString()
                //<< ":giaddr=" << request->getHeader().getGiaddr().toString();
                return request;
              }
            }
            throw std::invalid_argument("no interface found in received packet");
          }
          virtual void Stop() { }
      };
    }
  }
  class RelayTor {
    private:
      class Xid {
        private:
          struct timeval created ;
          short sourcePort = -1;
        public:
          Xid() { }
          //Xid(const Xid &other) : relays(other.relays) {
          //  this->created = other.created;
          //}
          Xid(struct timeval &_now, short _sourcePort) : created(_now), sourcePort(_sourcePort) {
          }
          bool ageable(struct timeval &now) {
            return ((((now.tv_sec - created.tv_sec) * 1000000) + (now.tv_usec - created.tv_usec))/1000) >= 5000;
          }
          const short getSourcePort() const {
            return sourcePort;
          }
          std::list<const std::unique_ptr<Relay>*> relays;
      };
      class Processor {
        private:
          PacketSource& ps;
          bool processRequest(std::unique_ptr<Request> &dr, struct timeval &now, Xid &xid) {
            for(const std::unique_ptr<Relay>& relay: ps.Relays()) {
              if (dr->getIfIndex() == relay->getIfIndex()) {
                if (!dr->getHeader().getGiaddr().isSet()) {
                  dr->getHeader().getGiaddr().assign(relay->getGatewayIp());
                }
                ps.Send(*dr, relay->getServerIp(), relay->getServerPort());
                xid.relays.push_back(&relay);
              }
            }
            return !xid.relays.empty();
          }
          static void age(std::map<int, Xid> &xids, struct timeval& now) {
            // age to old entries
            for(std::map<int, Xid>::iterator itr = xids.begin(); itr != xids.end(); ++itr) {
              if (itr->second.ageable(now)) {
                xids.erase(itr);
              }
            }
          }
        public:
          Processor(PacketSource &_ps) : ps(_ps) {
          }
          void start() {
            ps.Start();
            std::map<int, Xid> xids;
            while (1) {
              std::unique_ptr<Request> dr = ps.Recv();
              struct timeval now;
              gettimeofday(&now, 0);
              age(xids, now);
              if (dr->getHeader().incHops()) {
                // is a loop
                continue;
              }
              if (dr->getHeader().isRequest()) {
                L(DEBUG) << "Process Request(" << dr->getHeader().getXid() << ")";
                Xid xid(now, dr->getSourcePort());
                if (!processRequest(dr, now, xid)) {
                  continue;
                }
                xids[dr->getHeader().getXid()] = xid;
              }
              if (dr->getHeader().isReply()) {
                L(DEBUG) << "Process Replay(" << dr->getHeader().getXid() << ")";
                const auto& xid = xids.find(dr->getHeader().getXid());
                if (xid == xids.end()) {
                  L(DEBUG) << "No Xid found for " << dr->getHeader().getXid();
                  continue;
                }
                if (dr->getHeader().getCiaddr().isSet()) {
                  ps.Send(*dr, dr->getHeader().getCiaddr(), xid->second.getSourcePort());
                } else {
                  L(DEBUG) << "No Ciaddr set for " << dr->getHeader().getXid();
                }
              }
              ps.Stop();
            }
          }
      };

      class ProcessFactory {
        private:
          PacketSource &ps;
          class ProcessorThread {
            private:
              std::unique_ptr<Processor> processor;
              std::unique_ptr<std::thread> thread;
            public:
              ProcessorThread(Processor *_processor) : processor(_processor),
              thread(new std::thread(&ProcessFactory::delegate, _processor)) {
              }
              std::thread& getThread() {
                return *thread;
              }
          };
          std::list<ProcessorThread> processors;
        public:
          ProcessFactory(PacketSource &_ps) : ps(_ps) { }
          std::list<ProcessorThread> &getThreads() {
            return processors;
          }
          void run() {
            std::set<int> ports;
            for(const std::unique_ptr<Relay>& relay: ps.Relays()) {
              ports.insert(relay->getListenPort());
            }
            for(int port: ports) {
              processors.push_back(ProcessorThread(new Processor(ps)));
            }
          }
          static void delegate(Processor *processor) {
            processor->start();
          }
      };
      std::list<ProcessFactory> processorFactories;
    public:
      void addPacketSource(PacketSource &ps) {
        processorFactories.push_back(ProcessFactory(ps));
        processorFactories.back().run();
      }
      void run() {
        while (processorFactories.begin() != processorFactories.end()) {
          if (processorFactories.front().getThreads().empty()) {
            sleep(1);
            continue;
          }
          processorFactories.front().getThreads().front().getThread().join();
        }
      }
  };
}

std::vector<std::string> split(const char *str, char c = ' ')
{
  std::vector<std::string> result;

  do
  {
    const char *begin = str;

    while(*str != c && *str)
      str++;

    result.push_back(std::string(begin, str));
  } while (0 != *str++);

  return result;
}

void daemonizer(const char *pidfname) {
  if (pid_t pid = fork()) {
    if (pid > 0) {
      exit(0);
    }
    else {
      L(ERROR) << "First fork failed: %m";
    }
  }
  setsid();
  chdir("/");
  umask(0);
  if (pid_t pid = fork()) {
    if (pid > 0) {
      exit(0);
    } else {
      L(ERROR) << "Second fork failed: %m";
    }
  }
  close(0);
  close(1);
  close(2);
  if (open("/dev/null", O_RDONLY) < 0) {
    throw std::system_error(std::error_code(errno,std::generic_category()), "Unable to open /dev/null");
  }
  if (dup(0) < 0) {
    throw std::system_error(std::error_code(errno,std::generic_category()), "dup failed");
  }
  if (dup(0) < 0) {
    throw std::system_error(std::error_code(errno,std::generic_category()), "dup failed");
  }
  std::ofstream pidstream;
  pidstream.open(pidfname, std::ios::trunc);
  pidstream << getpid() << std::endl;
  pidstream.close();
}

_INITIALIZE_EASYLOGGINGPP

/*
   std::string basename(const char *path) {
   int idx = path.rindex(path, '/');
   return std::string(&path[idx < 0 ? 0 : idx+1])
   }
   */

int getopter(int argc, char **argv, Dhcp::Linux::V4PacketSource& linuxV4PacketSource) {
  int c;
  int digit_optind = 0;

  while (1) {
    int this_option_optind = optind ? optind : 1;
    int option_index = 0;
    static struct option long_options[] = {
      {"relay",   required_argument, 0,  0 },
      {"daemon",   required_argument, 0,  0 },
      {0,         0,                 0,  0 }
    };

    c = getopt_long(argc, argv, "d:r:", long_options, &option_index);
    if (c == -1)
      break;

    switch (c) {
      case 'r':
        {
          std::vector<std::string> params = split(optarg, '%');
          if (params.size() != 5) {
            throw std::invalid_argument(Formatter() << "can not parse parameter need 4 %:" << optarg);
          }
          L(INFO) << "addRelay(" << params[0] << "," << params[1] << "," << params[2] << "," << params[3] << "," << params[4];
          linuxV4PacketSource.addRelay(params[0].c_str(), (short)std::stoi(params[1]),
              params[2].c_str(), (short)std::stoi(params[3]), params[4].c_str());
        }
        break;

      case 'd':
        {
          L(INFO) << "starting relaytor as daemon:" << basename(argv[0]);
          activeLoggerId = el::base::consts::kSysLogLoggerId;
          activeDispatchAction = el::base::DispatchAction::SysLog;
          daemonizer(optarg);
          _INIT_SYSLOG(basename(argv[0]), LOG_PID | LOG_CONS | LOG_PERROR, LOG_USER);
          L(INFO) << "started relaytor as daemon";
        }
        break;

      default:
        printf("?? getopt returned character code 0%o ??\n", c);
        break;
    }
  }

}

int main(int argc, char **argv) {

  _START_EASYLOGGINGPP(argc, argv);


  try {
    Dhcp::Linux::V4::PacketSource linuxV4PacketSource;
    Dhcp::Linux::V6::PacketSource linuxV6PacketSource;
    bool found = false;
    getopter(argc, argv, linuxV4PacketSource, linuxV6PacketSource);
    if (linuxV4PacketSource.Relays().begin() == linuxV4PacketSource.Relays().end()) {
      throw std::invalid_argument("need atleast one argument");
    }
    if (linuxV6PacketSource.Relays().begin() == linuxV6PacketSource.Relays().end()) {
      throw std::invalid_argument("need atleast one argument");
    }
    Dhcp::RelayTor relayTor;
    relayTor.addPacketSource(linuxV4PacketSource);
    relayTor.addPacketSource(linuxV6PacketSource);
    relayTor.run();
  } catch (const std::exception& e) {
    L(ERROR) << e.what();
  }
}
