

#include <iostream>       // std::cerr
#include <typeinfo>       // operator typeid
#include <cerrno>         // errno
#include <list>         // errno
#include <map>         // errno
#include <thread>         // errno
#include <system_error>
#include <exception>
#include <memory>


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

namespace Dhcp {
  class SocketAddr {
    public:
      virtual void assign(SocketAddr &other);
  }
  class Header {
    public:
      virtual void *getPacket() = 0;
      virtual size_t getPacketSize() const = 0;
      virtual bool isRequest() const = 0;
      virtual bool incHops() = 0;
      virtual int getXid() const = 0;
      virtual const char *getCiaddrStr() = 0;
      virtual const char *getYiaddrStr() = 0;
      virtual const char *getSiaddrStr() = 0;
      virtual const char *getGiaddrStr() = 0;
      virtual const unsigned char *getSname() = 0;
      virtual const unsigned char *getFile() = 0;
      virtual bool hasGiaddr() = 0;
      virtual SocketAddr &getGiaddr() = 0;
  };

  namespace V4 {
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
        char bufCiAddr[INET_ADDRSTRLEN];
        char bufYiAddr[INET_ADDRSTRLEN];
        char bufSiAddr[INET_ADDRSTRLEN];
        char bufGiAddr[INET_ADDRSTRLEN];
      public:
        virtual ~Header() {}
        virtual void *getPacket() {
          return &packet;
        }
        virtual bool hasGiaddr() {
          return packet.header.giaddr.s_addr;
        }
        virtual void setGiaddr(struct sockaddr *) {
        }

        virtual bool isRequest() const {
          return packet.header.op == 1;
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
        virtual const char *getCiaddrStr() {
          return inet_ntop(AF_INET, &packet.header.ciaddr, bufCiAddr, sizeof(bufCiAddr));
        }
        virtual const char *getYiaddrStr() {
          return inet_ntop(AF_INET, &packet.header.yiaddr, bufYiAddr, sizeof(bufYiAddr));
        }
        virtual const char *getSiaddrStr() {
          return inet_ntop(AF_INET, &packet.header.siaddr, bufSiAddr, sizeof(bufSiAddr));
        }
        virtual const char *getGiaddrStr() {
          return inet_ntop(AF_INET, &packet.header.giaddr, bufGiAddr, sizeof(bufGiAddr));
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
      int socket = -1;
      struct ifreq ifr;
      std::unique_ptr<Header> header;
    public:
      Request(Header *_header) : header(_header) {
      }

      void *getPacket() {
        return this->header->getPacket();
      }
      size_t getPacketSize() {
        return this->header->getPacketSize();
      }
      const char *getIfName() {
        ifr.ifr_ifindex = this->getIfIndex();
        if (ioctl(this->socket, SIOCGIFNAME, &ifr) < 0) {
          throw std::system_error(std::error_code(errno,std::generic_category()), "can ioctl SIOCGIFNAME");
        }
        return ifr.ifr_name;
      }

      void setSocket(int socket) {
        this->socket = socket;
      }
      void setSize(int size) {
        this->size = size;
      }

      void setIfIndex(int ifindex) {
        this->ifindex = ifindex;
      }

      int getSize() {
        return this->size;
      }

      size_t getIfIndex() {
        return this->ifindex;
      }
      Header &getHeader() {
        return *(this->header);
      }

  };

  class Relay {
    public:
      virtual size_t getIfIndex() = 0;
      virtual SocketAddr &getRelaySrcAddr();
      virtual SocketAddr &getServerIp();
  };

  class PacketSource {
    public:
      virtual ~PacketSource() {}
      virtual void Start() = 0;
      virtual std::unique_ptr<Request> Recv() = 0;
      virtual std::list<Relay>& Relays() = 0;
      virtual void Stop() = 0;
  };


  namespace Linux {

    class Relay : public Dhcp::Relay {
      private:
        struct in_addr serverIp;
        struct in_addr relaySrcAddr;
        size_t ifIndex = -1;
        struct in_addr inIfaceSrcAddr;
      public:
        virtual size_t getIfIndex() {
          return ifIndex;
        }
        class Socket {
          public:
            const int fd = socket(PF_INET, SOCK_DGRAM, 0);
            ~Socket() {
              close(fd);
            }
        };
        Relay(const char *inIface, const char *serverIp, const char *relaySrcAddr) {
          const Socket socket;
          if (inet_pton(AF_INET, serverIp, &this->serverIp) <= 0) {
            throw std::invalid_argument("can not parse address");
          }
          if (inet_pton(AF_INET, relaySrcAddr, &this->relaySrcAddr) <= 0) {
            throw std::invalid_argument("can not parse address");
          }
          struct ifreq ifr;
          ifr.ifr_addr.sa_family = AF_INET;
          bool found = false;
          for(int idx = 1; true ; ++idx) {
            ifr.ifr_ifindex = idx;
            std::cout << ifr.ifr_ifindex << std::endl;
            if (ioctl(socket.fd, SIOCGIFNAME, &ifr) < 0) {
              if (errno != ENODEV) {
                throw std::invalid_argument("can get interfaces name");
              }
              break;
            }
            std::cout << ifr.ifr_name << std::endl;
            if (ioctl (socket.fd, SIOCGIFADDR, &ifr) < 0) {
              throw std::invalid_argument("can get interfaces address");
            }
            const in_addr iface_addr = ((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr;
            if (!strncmp(inIface, ifr.ifr_name, sizeof(ifr.ifr_name)) && ifIndex < 0) {
              if (ioctl (socket.fd, SIOCGIFFLAGS, &ifr) < 0 || !(ifr.ifr_flags & IFF_BROADCAST)) {
                throw std::invalid_argument("the relay if is not a broadcast device");
              }
              inIfaceSrcAddr = iface_addr;
              ifIndex = ifr.ifr_ifindex;
            }
            if (!memcmp(&iface_addr, &this->relaySrcAddr, sizeof(iface_addr))) {
              found = true;
            }
          }
          if (!found) {
            throw std::invalid_argument("relaySrcAddr must be a localAddress");
          }
        }
    };

    class IPV4Socket : public PacketSource {
      private:
        int sock = -1;
        int port = 67;
        std::list<Request> requests;
        std::list<Relay> relays;
      public:
        void setPort(int port) {
          this->port = port;
        }
        void addRelay(const char *inIface, const char *serverIp, const char *relaySrcAddr) {
          relays.push_back(Relay(inIface, serverIp, relaySrcAddr));
        }
        virtual std::list<Dhcp::Relay>& Relays() {
          return relays;
        }
        virtual void Start() {
          if (sock >= 0) {
            throw std::invalid_argument("start has called without close");
          }
          sock = socket(PF_INET, SOCK_DGRAM, 0);
          if (sock < 0) {
            throw std::system_error(std::error_code(errno,std::generic_category()), "can open socket");
          }
          const int oneopt = 1;
          if (setsockopt(sock, SOL_IP, IP_PKTINFO, &oneopt, sizeof(oneopt)) < 0) {
            throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_PKTINFO");
          }
          if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &oneopt, sizeof(oneopt)) < 0) {
            throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_SOCKET, SO_BROADCAST");
          }
          const int mtuopt = IP_PMTUDISC_DONT;
          if (setsockopt(sock, SOL_IP, IP_MTU_DISCOVER, &mtuopt, sizeof(mtuopt)) < 0) {
            throw std::system_error(std::error_code(errno,std::generic_category()), "can setsocketopt SOL_IP, IP_MTU_DISCOVER");
          }
          struct sockaddr_in saddr;
          saddr.sin_family = AF_INET;
          saddr.sin_port = htons(port);
          saddr.sin_addr.s_addr = INADDR_ANY;
          if (bind(sock, (struct sockaddr *)&saddr, sizeof(struct sockaddr_in))) {
            throw std::system_error(std::error_code(errno,std::generic_category()), "can bind udp port");
          }
        }

        virtual std::unique_ptr<Request> Recv() {
          std::unique_ptr<Request> request(new Request(new Dhcp::V4::Header()));
          struct sockaddr_in saddr;
          struct msghdr msg;
          struct iovec iov;
          union {
            struct cmsghdr align; /* this ensures alignment */
            char control[CMSG_SPACE(sizeof(struct in_pktinfo))];
          } control_u;

          msg.msg_control = control_u.control;
          msg.msg_controllen = sizeof(control_u);
          msg.msg_name = &saddr;
          msg.msg_namelen = 0;
          msg.msg_iov = &iov;
          msg.msg_iovlen = 1;
          iov.iov_base = request->getPacket();
          iov.iov_len = request->getPacketSize();

          int size = recvmsg(this->sock, &msg, 0);
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
              request->setSocket(sock);
              request->setIfIndex(p.p->ipi_ifindex);
              request->setSize(size);
              std::cout << "Size:" << request->getSize() << ":" << request->getIfIndex() << std::endl;
              std::cout << ":name=" << request->getIfName() << std::endl;
              std::cout << ":xid=" << request->getHeader().getXid() << std::endl;
              std::cout << ":ciaddr=" << request->getHeader().getCiaddrStr() << std::endl;
              std::cout << ":yiaddr=" << request->getHeader().getYiaddrStr() << std::endl;
              std::cout << ":siaddr=" << request->getHeader().getSiaddrStr() << std::endl;
              std::cout << ":giaddr=" << request->getHeader().getGiaddrStr() << std::endl;
              return request;
            }
          }
          throw std::invalid_argument("no interface found in received packet");
        }
        virtual void Stop() {
          if (sock >= 0) {
            close(sock);
          }
        }
    };
  }
  class RelayTor {
    private:
      class Actor {
        private:
          PacketSource &ps;
          std::thread *thread = 0;
        public:
          Actor(PacketSource &_ps) : ps(_ps) {
          }

          ~Actor() {
            if (thread) {
              delete thread;
            }
          }

          std::thread* getThread() {
            return thread;
          }
          Actor& run() {
            thread = new std::thread(&Actor::delegate, this);
            return *this;
          }
          class Xid {
            private:
              struct timeval created;
            public:
              Xid(struct timeval &_now) {
                created = _now;
              }
              bool ageable(struct timeval &now) {
                return ((((now.tv_sec - created.tv_sec) * 1000000) + (now.tv_usec - created.tv_usec))/1000) >= 5000;
              }
              std::list<Relay *> relays;
          };
          void start() {
            ps.Start();
            std::map<int, Xid> xids;
            while (1) {
              std::unique_ptr<Request> dr = ps.Recv();
              struct timeval now;
              gettimeofday(&now, 0);
              if (dr->getHeader().incHops()) {
                // is a loop
                continue;
              }
              if (dr->getHeader().isRequest()) {
                Xid xid(now);
                for(Relay& relay: ps.Relays()) {
                  if (dr->getIfIndex() == relay.getIfIndex()) {
                    if (!dr->getHeader().hasGiaddr()) {
                      dr->getHeader().getGiaddr().assign(relay.getRelaySrcAddr());
                    }
                    ps.Send(dr, relay.getRelaySrcAddr(), relay.getServerIp());
                    xid.relays.push_back(relay);
                  }
                }
                if (xid.relays.empty()) {
                  continue;
                }
                xids[dr->getHeader().getXid()] = xid;
              }
              // age to old entries
              for(std::map<int, Xid>::iterator itr = xids.begin(); itr != xids.end(); ++itr) {
                if (itr->ageable(now)) {
                  xids.erase(itr);
                }
              }
            }
            ps.Stop();
          }
          static void delegate(Actor *ac) {
            ac->start();
          }
      };
      std::list<Actor> actors;
    public:
      void addPacketSource(PacketSource &ps) {
        actors.push_back(Actor(ps));
        actors.back().run();
      }
      void run() {
        while (actors.begin() != actors.end()) {
          std::thread *thread = actors.front().getThread();
          if (thread) {
            thread->join();
          } else {
            sleep(1);
          }
        }
      }
  };
}


int main(int argc, char **argv) {
  Dhcp::Linux::IPV4Socket linuxIPV4Socket;
  linuxIPV4Socket.addRelay("eth0", "192.168.176.1", "192.168.176.110");
  Dhcp::RelayTor relayTor;
  relayTor.addPacketSource(linuxIPV4Socket);
  relayTor.run();
}
