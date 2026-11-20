(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class BreakoutGame extends MiniScene{
 setupGame(){this.duration=45;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),L=p.cy-p.h/2,T=p.cy+p.h/2,pw=60,st={p,L,T,pw,px:0,tx:0,ball:{x:0,y:L+40,vx:0,vy:0,on:true},lives:3,bricks:[],hearts:[],speed:230,cpu:0};
  st.pad=new Sprite(Gfx.pill(pw,10,s.color,'#fff',5,false),pw,10);st.pad.y=L+20;st.pad.z=6;s.field.add(st.pad);
  st.bn=new Node();const g=new Sprite(Gfx.glow(),30,30);g.color=s.color;g.cbf=1;g.blend='add';g.alpha=.7;st.bn.add(g);st.bn.add(new Sprite(Gfx.circle(6,'#fff',null),12,12));st.bn.z=8;s.field.add(st.bn);
  for(let i=0;i<3;i++){const h=label('♥',14,s.color);h.x=p.w/2-14-i*16;h.y=T-10;h.z=9;s.field.add(h);st.hearts.push(h)}
  this.mkb(s,st);if(!s.isCPU){const h=label('FINGER ZIEHEN – TIPPEN ZUM START',11,white(1,.7));h.y=L+60;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(6),A.fadeOut(.5),A.remove()]))}return st})}
 mkb(s,st){const cols=7,bw=(st.p.w-24)/cols,bh=16,rows=4,cs=['#ff4d4d','#ff9f1a','#ffd61a','#40ff73'];for(const b of st.bricks)b.n.run(A.remove());st.bricks=[];
  for(let r=0;r<rows;r++)for(let c=0;c<cols;c++){const n=new Sprite(Gfx.pill(bw-3,bh-3,cs[r],null,4,true),bw-3,bh-3);n.x=-st.p.w/2+12+bw*(c+.5);n.y=st.T-48-r*bh;n.z=4;n.alpha=0;n.run(A.sequence([A.wait((r+c)*.03),A.fadeIn(.2)]));s.field.add(n);st.bricks.push({n,x:n.x,y:n.y,w:bw,h:bh,pts:rows-r})}}
 gameUpdate(dt){for(const s of this.seats){const st=this.st[s.index],b=st.ball,hw=st.p.w/2;if(st.lives<=0)continue;
  if(s.isCPU){if(b.on){st.cpu+=dt;if(st.cpu>.6){st.cpu=0;this.launch(s,st)}}else{st.tx=b.x+Math.sin(this.elapsed*1.3)*(1-s.skill)*50}}
  const maxv=s.isCPU?150+s.skill*350:1e9;st.px+=NK.clamp(st.tx-st.px,-maxv*dt,maxv*dt);st.px=NK.clamp(st.px,-hw+st.pw/2+4,hw-st.pw/2-4);st.pad.x=st.px;
  if(b.on){b.x=st.px;b.y=st.L+34}else{const steps=2;for(let k=0;k<steps;k++){b.x+=b.vx*dt/steps;b.y+=b.vy*dt/steps;
   if(b.x<-hw+6){b.x=-hw+6;b.vx=Math.abs(b.vx)}if(b.x>hw-6){b.x=hw-6;b.vx=-Math.abs(b.vx)}if(b.y>st.T-6){b.y=st.T-6;b.vy=-Math.abs(b.vy)}
   if(b.vy<0&&b.y<st.L+30&&b.y>st.L+14&&Math.abs(b.x-st.px)<st.pw/2+6){const off=(b.x-st.px)/(st.pw/2),sp=Math.min(420,Math.hypot(b.vx,b.vy)+6);b.vx=off*sp*.8;b.vy=Math.sqrt(Math.max(1,sp*sp-b.vx*b.vx));b.y=st.L+30;Sfx.play('tap');st.pad.run(A.sequence([A.scaleTo(1.1,.04),A.scaleTo(1,.06)]))}
   for(const br of st.bricks){if(br.dead)continue;if(Math.abs(b.x-br.x)<br.w/2+5&&Math.abs(b.y-br.y)<br.h/2+5){br.dead=true;const ox=(br.w/2+5)-Math.abs(b.x-br.x),oy=(br.h/2+5)-Math.abs(b.y-br.y);if(ox<oy)b.vx=-b.vx;else b.vy=-b.vy;this.addScore(s,br.pts);this.addStat('hits',1,s);const pos={x:br.x,y:br.y};s.burst(pos,br.n.color||s.color,8,100);br.n.run(A.sequence([A.group([A.scaleTo(1.4,.12),A.fadeOut(.12)]),A.remove()]));s.floatText('+'+br.pts,pos,'#fff',14);Sfx.play('pop');break}}
   st.bricks=st.bricks.filter(x=>!x.dead);if(!st.bricks.length){this.mkb(s,st);s.banner('NEUE RUNDE','#ff0',24,.6);b.on=true}}
   if(b.y<st.L){st.lives--;if(st.hearts[st.lives])st.hearts[st.lives].alpha=.2;Sfx.play('miss');s.flash('#f00',.3);s.shake(5);b.on=true;if(st.lives<=0){s.knockOut('RAUS');st.bn.hidden=true;if(this.seats.every(o=>this.st[o.index].lives<=0))this.finishGame()}}}
  st.bn.x=b.x;st.bn.y=b.y}}
 began(s,at){const st=this.st[s.index];st.tx=at.x;if(st.ball.on)this.launch(s,st)}
 moved(s,at){this.st[s.index].tx=at.x}
 launch(s,st){const b=st.ball;if(!b.on)return;b.on=false;const a=NK.rr(-.4,.4);b.vx=Math.sin(a)*st.speed;b.vy=Math.cos(a)*st.speed;Sfx.play('kick')}
}
Arcade.register('breakout',BreakoutGame);})();
