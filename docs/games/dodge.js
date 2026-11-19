(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const BEARH=32,HALFW=11;
class DodgeGame extends MiniScene{
 feetY(s){return -s.h/2+8}limit(s){return s.w/2-22}
 setupGame(){this.duration=45;this.states=[];
  for(const s of this.seats){const bear=this.makeBear(s,BEARH,false),st={seat:s,rand:this.newRand(),bear,pucks:[],x:0,target:0,lives:3,invuln:0,spawnT:.3,surv:0,bonus:0};
   const floor=new Sprite(null,s.w,3,s.color);floor.alpha=.7;floor.y=this.feetY(s)-2;floor.z=2;s.field.add(floor);
   const fg=new Sprite(Gfx.glow(),s.w*1.2,30);fg.color=s.color;fg.cbf=1;fg.blend='add';fg.alpha=.4;fg.y=floor.y;s.field.add(fg);
   bear.x=0;bear.y=this.feetY(s);bear.z=20;s.field.add(bear);bear.startRun(.1);
   const ll=label('●●●',13,s.color);ll.ha='left';ll.x=-s.w/2+14;ll.y=s.h/2-34;ll.z=400;s.node.add(ll);st.lifeLabel=ll;
   const hint=label(s.isCPU?'CPU':'↔ ZIEHEN',s.w>300?18:13,white(1,.85));hint.z=30;s.field.add(hint);hint.run(A.sequence([A.wait(4.7),A.fadeOut(.4),A.remove()]));
   this.states.push(st)}}
 spawn(st){const s=st.seat,frac=st.rand.double(),sp=150+this.elapsed*4.5+st.rand.range(0,50),r=st.rand.range(8,11),node=new Node();
  node.add(new Sprite(Gfx.circle(r,white(.08),Theme.orange),r*2,r*2));const g=new Sprite(Gfx.glow(),r*4.5,r*4.5);g.color=Theme.orange;g.cbf=1;g.blend='add';g.alpha=.7;g.z=-1;node.add(g);node.z=10;
  const x=(frac*2-1)*(s.w/2-r),p={node,x,y:s.h/2+r,v:sp*s.h/370,r,noise:Math.random()*2-1,counted:false};node.x=p.x;node.y=p.y;node.run(A.forever(A.rotateBy(6,1)));s.field.add(node);st.pucks.push(p)}
 hit(st){const s=st.seat;st.lives--;st.invuln=1.3;st.lifeLabel.text='●'.repeat(Math.max(0,st.lives));s.burst({x:st.x,y:this.feetY(s)+16},'#f00',12);s.shake(5);s.flash('#f00',.3);st.bear.squash();
  if(!s.isCPU){Sfx.play('hit');Haptic.bad()}
  if(st.lives<=0){s.knockOut('RAUS');st.bear.stopRun();for(const p of st.pucks)p.node.removeFromParent();st.pucks=[]}}
 gameUpdate(dt){for(const st of this.states){const s=st.seat;if(!s.alive)continue;st.surv+=dt;st.invuln-=dt;st.bear.visual.alpha=st.invuln>0?(Math.floor(st.invuln*12)%2===0?.35:1):1;
   st.spawnT-=dt;if(st.spawnT<=0){const dens=Math.max(.2,.62-this.elapsed*.01)*Math.pow(390/s.w,.5);st.spawnT+=dens;this.spawn(st);if(st.rand.chance(Math.min(.4,this.elapsed*.01)))this.spawn(st)}
   if(s.isCPU)this.cpuThink(st,dt);
   const maxStep=900*dt;st.x+=Math.max(-maxStep,Math.min(maxStep,st.target-st.x));st.x=Math.max(-this.limit(s),Math.min(this.limit(s),st.x));st.bear.x=st.x;
   const cy=this.feetY(s)+BEARH*.45;let i=0;
   while(i<st.pucks.length){const p=st.pucks[i],prev=p.y;p.y-=p.v*dt;p.node.y=p.y;let removed=false;const dx=Math.abs(p.x-st.x);
    if(st.invuln<=0&&dx<HALFW+p.r*.8&&Math.abs(p.y-cy)<BEARH*.45+p.r*.8){p.node.removeFromParent();st.pucks.splice(i,1);removed=true;this.hit(st);if(!s.alive)break}
    else if(!p.counted&&prev>cy&&p.y<=cy){p.counted=true;if(dx<HALFW+p.r+12){st.bonus+=2;s.floatText('KNAPP! +2',{x:st.x,y:cy+26},'#ff0',14);if(!s.isCPU)Sfx.play('coin')}}
    if(!removed&&p.y<-s.h/2-20){p.node.removeFromParent();st.pucks.splice(i,1);removed=true}
    if(!removed)i++}
   const sc=Math.floor(st.surv)+st.bonus;if(sc!==s.score)this.setScore(s,sc)}
  if(this.phase==='playing')this.checkEnd()}
 cpuThink(st,dt){const s=st.seat,look=.45+.55*s.skill,cy=this.feetY(s)+BEARH*.45,reach=280+220*s.skill;let best=st.x,bestCost=Infinity;const steps=15,lim=this.limit(s);
  for(let k=0;k<steps;k++){const cx=-lim+2*lim*k/(steps-1);let cost=Math.abs(cx-st.x)*.004;
   for(const p of st.pucks){const t=(p.y-cy)/p.v;if(t<-.1||t>look)continue;const px=p.x+p.noise*(1-s.skill)*28,need=HALFW+p.r+8,dxMove=Math.abs(cx-st.x);
    if(Math.abs(px-cx)<need)cost+=3/(Math.max(t,0)+.15);if(dxMove>reach*Math.max(t,.02)&&Math.abs(px-st.x)<need)cost+=6}
   if(cost<bestCost-.001){bestCost=cost;best=cx}}
  const step=reach*dt;st.target=st.x+Math.max(-step,Math.min(step,best-st.x))}
 checkEnd(){const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others+2)this.finishGame()}}
 began(seat,at){const st=this.states.find(s=>s.seat===seat);if(st)st.target=at.x}
 moved(seat,at){const st=this.states.find(s=>s.seat===seat);if(st)st.target=at.x}
}
Arcade.register('dodge',DodgeGame);
})();
