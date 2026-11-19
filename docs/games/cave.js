(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COLW=6,R=8,ACCEL=820;
const DARK=rgba(.1,.07,.2);
class CaveGame extends MiniScene{
 yLo(s){return -s.h/2+8}yHi(s){return s.h/2-34}px(s){return -s.w*.25}
 gapAt(s,d){const base=Math.min(130,s.h*.36);return Math.max(base*.62,base-d*.012)+12*Math.sin(d*.01+this.p3)}
 centre(s,d){const g=this.gapAt(s,d),amp=Math.max(0,(this.yHi(s)-this.yLo(s)-g)/2-4),mid=(this.yHi(s)+this.yLo(s))/2,m=Math.min(1,.35+d/2500);return mid+amp*m*(.6*Math.sin(d*.011+this.p1)+.4*Math.sin(d*.029+this.p2))}
 setupGame(){this.duration=45;const rr=this.newRand();this.p1=rr.range(0,6);this.p2=rr.range(0,6);this.p3=rr.range(0,6);this.states=[];
  for(const s of this.seats){const bear=this.makeBear(s,26,true),st={seat:s,bear,puck:new Node(),tops:[],bots:[],capT:[],capB:[],y:0,vy:0,dist:0,holding:false,noise:0,noiseT:0,trailT:0};
   const count=Math.floor(s.w/COLW)+3,top=s.h/2,bottom=-s.h/2;
   for(let i=0;i<count;i++){const x=-s.w/2+i*COLW;
    const t=new Sprite(null,COLW+.5,10,DARK);t.ay=0;t.x=x;t.y=top-10;t.z=3;
    const b=new Sprite(null,COLW+.5,10,DARK);b.ay=1;b.x=x;b.y=bottom+10;b.z=3;
    const ct=new Sprite(null,COLW+.5,4,s.color);ct.x=x;ct.y=0;ct.z=4;const cb=new Sprite(null,COLW+.5,4,s.color);cb.x=x;cb.y=0;cb.z=4;
    for(const n of[t,b,ct,cb])s.field.add(n);st.tops.push(t);st.bots.push(b);st.capT.push(ct);st.capB.push(cb)}
   const body=new Sprite(Gfx.circle(R,white(.1),Theme.orange),R*2,R*2);st.puck.add(body);
   const g=new Sprite(Gfx.glow(),R*5,R*5);g.color=Theme.orange;g.cbf=1;g.blend='add';g.alpha=.8;g.z=-1;st.puck.add(g);
   bear.x=0;bear.y=R-2;bear.z=1;st.puck.add(bear);st.puck.z=20;st.puck.x=this.px(s);st.puck.y=0;s.field.add(st.puck);
   const hint=label(s.isCPU?'CPU':'HALTEN = HOCH',s.w>300?18:13,white(1,.9));hint.y=-s.h*.3;hint.z=30;s.field.add(hint);hint.run(A.sequence([A.wait(4.7),A.fadeOut(.4),A.remove()]));
   st.y=this.centre(s,this.px(s));this.states.push(st);this.layoutCols(st)}}
 layoutCols(st){const s=st.seat;for(let i=0;i<st.tops.length;i++){const x=st.tops[i].x,d=st.dist+x+s.w/2,c=this.centre(s,d),g=this.gapAt(s,d),topEdge=c+g/2,botEdge=c-g/2;
  st.tops[i].h=Math.max(1,s.h/2-topEdge);st.tops[i].y=topEdge;st.bots[i].h=Math.max(1,botEdge+s.h/2);st.bots[i].y=botEdge;st.capT[i].y=topEdge-1;st.capB[i].y=botEdge+1}}
 crash(st){const s=st.seat;if(!s.alive)return;s.knockOut('CRASH');s.shake(7);s.burst({x:this.px(s),y:st.y},s.color,16,140);s.flash('#f00',.3);if(!s.isCPU){Sfx.play('hit');Haptic.bad()}st.puck.run(A.fadeOut(.2))}
 gameUpdate(dt){for(const st of this.states){const s=st.seat;if(!s.alive)continue;const speed=(105+this.elapsed*2.2)*(.75+.25*s.w/390);st.dist+=speed*dt;
   if(s.isCPU)this.cpuThink(st,dt,speed);
   st.vy+=(st.holding?ACCEL:-ACCEL)*dt;st.vy=Math.max(-300,Math.min(300,st.vy));st.y+=st.vy*dt;st.puck.y=st.y;st.puck.rot=Math.max(-.5,Math.min(.5,st.vy/500))*-.6;this.layoutCols(st);
   st.trailT-=dt;if(st.trailT<=0){st.trailT=.04;const d=new Sprite(Gfx.dot(),6,6);d.color=st.holding?Theme.orange:s.color;d.cbf=1;d.blend='add';d.x=this.px(s)-6;d.y=st.y;d.z=10;s.field.add(d);d.run(A.sequence([A.group([A.moveBy(-30,0,.35),A.fadeOut(.35)]),A.remove()]))}
   let dead=false;for(const dx of[-R+2,0,R-2]){const d=st.dist+this.px(s)+s.w/2+dx,c=this.centre(s,d),g=this.gapAt(s,d);if(st.y+R-2>c+g/2||st.y-R+2<c-g/2)dead=true}
   if(dead){this.crash(st);continue}
   const sc=Math.floor(st.dist/10);if(sc!==s.score){s.score=sc;if(s.scoreLabel)s.scoreLabel.text=''+sc}}
  this.checkEnd()}
 cpuThink(st,dt,speed){const s=st.seat;st.noiseT-=dt;if(st.noiseT<=0){st.noiseT=.5;st.noise=(Math.random()*2-1)*(1-s.skill)*this.gapAt(s,st.dist)*.3}
  const lookX=20+s.skill*20,d=st.dist+this.px(s)+s.w/2+lookX,target=this.centre(s,d)+st.noise,predicted=st.y+st.vy*.11,hold=predicted<target;
  if(Math.random()<(1-s.skill)*.01)st.holding=!st.holding;else st.holding=hold}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
 began(seat){const st=this.states.find(s=>s.seat===seat);if(st){st.holding=true;if(!seat.isCPU)Sfx.play('tap')}}
 ended(seat){const st=this.states.find(s=>s.seat===seat);if(st)st.holding=false}
}
Arcade.register('cave',CaveGame);
})();
