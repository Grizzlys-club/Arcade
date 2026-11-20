(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class BankGame extends MiniScene{
 setupGame(){this.duration=40;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),L=p.cy-p.h/2,T=p.cy+p.h/2,gw=100,st={p,L,T,gw,pos:{x:0,y:L+30},vel:{x:0,y:0},live:false,bounced:false,wait:.4,start:null,keeper:0,kdir:1,cpu:1.2};
  const goal=new Sprite(Gfx.goal(gw,26),gw+14,34);goal.y=T-14;goal.z=2;s.field.add(goal);
  st.kp=new Sprite(Gfx.pill(34,8,'#ff4d4d',null,4,false),34,8);st.kp.y=T-40;st.kp.z=4;s.field.add(st.kp);
  const pk=new Node();pk.add(new Sprite(Gfx.glow(),44,44));pk.children[0].color=s.color;pk.children[0].cbf=1;pk.children[0].blend='add';pk.children[0].alpha=.6;pk.add(new Sprite(Gfx.circle(11,'#222','#fff'),22,22));pk.z=8;pk.x=0;pk.y=st.pos.y;s.field.add(pk);st.puck=pk;
  const ob=new Sprite(Gfx.pill(46,12,white(1,.3),white(1,.6),6,false),46,12);ob.x=0;ob.y=p.cy+10;ob.z=3;s.field.add(ob);st.ob=ob;st.od=1;
  if(!s.isCPU){const h=label('WISCHEN INS TOR – ÜBER BANDE',12,white(1,.7));h.y=L+60;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}return st})}
 gameUpdate(dt){for(const s of this.seats){const st=this.st[s.index],p=st.p,hw=p.w/2-11;
  st.ob.x+=st.od*60*dt;if(Math.abs(st.ob.x)>hw-24)st.od*=-1;st.keeper+=st.kdir*dt*(70+this.elapsed*2);if(Math.abs(st.keeper)>st.gw/2-14)st.kdir*=-1;st.kp.x=st.keeper;
  if(!st.live){st.wait-=dt;if(st.wait<=0&&st.puck.alpha<1)st.puck.alpha=1;if(s.isCPU&&st.wait<=0){st.cpu-=dt;if(st.cpu<=0){st.cpu=NK.rr(1,1.6)+(1-s.skill);const ang=NK.rr(-1,1)*(1-s.skill)*.5+Math.atan2(NK.rr(-30,30),st.T-st.pos.y);this.shoot(s,{x:Math.sin(ang),y:Math.cos(ang)})}}continue}
  st.pos.x+=st.vel.x*dt;st.pos.y+=st.vel.y*dt;
  if(st.pos.x<-hw){st.pos.x=-hw;st.vel.x=Math.abs(st.vel.x);st.bounced=true;Sfx.play('bounce');s.burst(st.pos,'#fff',3,50)}if(st.pos.x>hw){st.pos.x=hw;st.vel.x=-Math.abs(st.vel.x);st.bounced=true;Sfx.play('bounce');s.burst(st.pos,'#fff',3,50)}
  if(Math.abs(st.pos.y-st.ob.y)<12&&Math.abs(st.pos.x-st.ob.x)<34){st.vel.y=-st.vel.y;st.pos.y+=st.vel.y*dt*2;st.bounced=true;Sfx.play('hit')}
  if(Math.abs(st.pos.y-st.kp.y)<12&&Math.abs(st.pos.x-st.kp.x)<28&&st.vel.y>0){st.vel.y=-st.vel.y*.6;Sfx.play('save')}
  if(st.pos.y>=st.T-22){if(Math.abs(st.pos.x)<st.gw/2){const pts=st.bounced?2:1;this.addScore(s,pts);this.addStat('goals',1,s);s.floatText(st.bounced?'BANDE! +2':'TOR +1',{x:st.pos.x,y:st.T-60},st.bounced?'#ff0':s.color,22);s.burst({x:st.pos.x,y:st.T-14},s.color,18,150);NK.ring(s,{x:st.pos.x,y:st.T-14},s.color,16);Sfx.play('goal');if(!s.isCPU)Haptic.good()}else{Sfx.play('miss')}this.reset(st)}
  else if(Math.hypot(st.vel.x,st.vel.y)<8||st.pos.y<st.L){this.reset(st)}
  st.vel.x*=Math.pow(.9,dt);st.puck.x=st.pos.x;st.puck.y=st.pos.y;if(Math.random()<.5){const t=NK.dot(s,s.color,12,6);t.x=st.pos.x;t.y=st.pos.y;t.alpha=.5;t.run(A.sequence([A.group([A.fadeOut(.3),A.scaleTo(.2,.3)]),A.remove()]))}}}
 reset(st){st.live=false;st.wait=.5;st.pos={x:0,y:st.L+30};st.puck.x=0;st.puck.y=st.pos.y;st.puck.alpha=.3;st.bounced=false}
 began(s,at){const st=this.st[s.index];if(!st.live&&st.wait<=0)st.start={x:at.x,y:at.y}}
 ended(s,at){const st=this.st[s.index];if(!st.start||st.live||st.wait>0){st.start=null;return}const dx=at.x-st.start.x,dy=at.y-st.start.y,l=Math.hypot(dx,dy);st.start=null;if(l<30||dy<10)return;this.shoot(s,{x:dx/l,y:dy/l})}
 shoot(s,d){const st=this.st[s.index];st.live=true;st.bounced=false;st.vel={x:d.x*560,y:d.y*560};st.puck.alpha=1;Sfx.play('kick');if(!s.isCPU)Haptic.tap('medium')}
}
Arcade.register('bank',BankGame);})();
