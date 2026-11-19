(()=>{
const {Node,Sprite,A,easeOut,Gfx,Theme,rgba,white,label}=SK;
class StackGame extends MiniScene{
 blockH(s){return s.w>300?24:20}baseY(s){return -s.h/2+30}
 setupGame(){this.duration=60;this.states=[];
  for(const s of this.seats){const st={seat:s,tower:new Node(),tops:[],moving:null,mx:0,mw:0,dir:1,level:0,cpuError:0,cpuDelay:0,combo:0};st.tower.z=5;s.field.add(st.tower);const bw=Math.min(s.w*.62,170);
   const ground=new Sprite(null,s.w,3,white(1,.15));ground.y=this.baseY(s)-this.blockH(s)/2-2;st.tower.add(ground);
   const bear=this.makeBear(s,34,true);bear.x=-s.w/2+26;bear.y=this.baseY(s)-this.blockH(s)/2;bear.z=3;st.tower.add(bear);bear.startBob(2,.5);
   st.tower.add(this.makeBlock(s,bw,0,0));st.tops=[{x:0,w:bw}];
   const hint=label(s.isCPU?'CPU':'TIPPEN = FALLEN LASSEN',s.w>300?17:12,white(1,.85));hint.y=s.h*.15;hint.z=40;s.field.add(hint);hint.run(A.sequence([A.wait(4.6),A.fadeOut(.4),A.remove()]));this.states.push(st)}}
 gameStarted(){for(const st of this.states)this.spawn(st)}
 makeBlock(s,w,level,x){const bh=this.blockH(s),node=new Sprite(null,w,bh-2,s.color);node.x=x;node.y=this.baseY(s)+level*bh;
  const dark=new Sprite(null,w,4,white(0,.25));dark.y=-(bh-2)/2+2;dark.z=1;node.add(dark);const stripe=new Sprite(null,w,3,white(1,.85));stripe.z=1;node.add(stripe);
  const hi=new Sprite(null,w,2,white(1,.35));hi.y=(bh-2)/2-1;hi.z=1;node.add(hi);return node}
 blockSpeed(st){return Math.min(300,95+st.level*7)*(.55+.45*st.seat.w/390)}
 range(st){return Math.max(10,st.seat.w/2-st.mw/2+st.mw*.3)}
 spawn(st){const s=st.seat;if(!s.alive||!st.tops.length)return;const top=st.tops[st.tops.length-1];st.level++;st.mw=top.w;st.dir=st.level%2===0?1:-1;st.mx=-st.dir*this.range(st);
  const b=this.makeBlock(s,st.mw,st.level,st.mx);st.tower.add(b);st.moving=b;
  if(s.isCPU){st.cpuError=(Math.random()*2-1)*((1-s.skill)*28+3);st.cpuDelay=.35}
  const topY=this.baseY(s)+st.level*this.blockH(s),want=Math.max(0,topY-s.h*.12);st.tower.removeAction('cam');st.tower.run(easeOut(A.moveToY(-want,.25)),'cam')}
 gameUpdate(dt){for(const st of this.states){const s=st.seat;if(!s.alive||!st.moving)continue;const r=this.range(st);st.mx+=st.dir*this.blockSpeed(st)*dt;
   if(st.mx>r){st.mx=r;st.dir=-1}if(st.mx<-r){st.mx=-r;st.dir=1}st.moving.x=st.mx;
   if(s.isCPU&&st.tops.length){const top=st.tops[st.tops.length-1];st.cpuDelay-=dt;const target=Math.max(-r,Math.min(r,top.x+st.cpuError));
    if((st.cpuDelay<=0&&Math.abs(st.mx-target)<=this.blockSpeed(st)*dt*1.2)||st.cpuDelay<-5)this.drop(st)}}
  this.checkEnd()}
 drop(st){const s=st.seat;if(!s.alive||!st.moving||!st.tops.length)return;const m=st.moving,top=st.tops[st.tops.length-1];st.moving=null;
  const dx=st.mx-top.x,overlap=st.mw-Math.abs(dx),y=m.y;m.removeFromParent();
  if(overlap<=0){const miss=this.makeBlock(s,st.mw,st.level,st.mx);st.tower.add(miss);
   miss.run(A.sequence([A.group([A.moveBy(st.dir*40,-s.h,.9),A.rotateBy(st.dir*-2,.9)]),A.remove()]));st.level--;s.knockOut('DANEBEN');Sfx.play('lose');if(!s.isCPU)Haptic.bad();return}
  if(Math.abs(dx)<=4){st.combo++;const b=this.makeBlock(s,st.mw,st.level,top.x);st.tower.add(b);st.tops.push({x:top.x,w:st.mw});
   const glow=new Sprite(Gfx.glow(),st.mw*1.6,50);glow.color='#fff';glow.cbf=1;glow.blend='add';glow.x=top.x;glow.y=y;glow.z=6;st.tower.add(glow);
   glow.run(A.sequence([A.group([A.scaleTo(1.5,.35),A.fadeOut(.35)]),A.remove()]));this.addScore(s,2);
   s.floatText(st.combo>1?'PERFEKT x'+st.combo:'PERFEKT!',{x:0,y:0},'#ff0',18);if(!s.isCPU){Sfx.play('coin');Haptic.good()}}
  else{st.combo=0;const nx=top.x+dx/2,b=this.makeBlock(s,overlap,st.level,nx);st.tower.add(b);st.tops.push({x:nx,w:overlap});
   const cutW=Math.abs(dx),cutX=dx>0?nx+overlap/2+cutW/2:nx-overlap/2-cutW/2,cut=this.makeBlock(s,cutW,st.level,cutX);cut.alpha=.8;st.tower.add(cut);const sign=dx>0?1:-1;
   cut.run(A.sequence([A.group([A.moveBy(sign*30,-s.h*.8,.8),A.rotateBy(sign*-1.5,.8),A.fadeOut(.8)]),A.remove()]));this.addScore(s,1);if(!s.isCPU)Sfx.play('stomp')}
  this.spawn(st)}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
 began(seat){const st=this.states.find(s=>s.seat===seat);if(st)this.drop(st)}
}
Arcade.register('stack',StackGame);
})();
