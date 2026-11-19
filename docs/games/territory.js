(()=>{
const {Node,Sprite,Label,A,Gfx,white,label}=SK;
const rnd=a=>a[Math.floor(Math.random()*a.length)];
class TerritoryGame extends MiniScene{
 setupGame(){this.duration=25;this.cols=5;this.rows=7;const N=this.cols*this.rows;
  this.owner=Array(N).fill(-1);this.cracked=Array(N).fill(false);this.tiles=[];this.marks=[];this.cs=[];this.org=[];
  this.cpuT=this.seats.map(()=>.2+Math.random()*.4);
  for(const s of this.seats){const top=34,usableH=s.h-top-16,cs=Math.floor(Math.min((s.w-16)/this.cols,usableH/this.rows));this.cs.push(cs);
   const gw=cs*this.cols,gh=cs*this.rows,o={x:-gw/2,y:-s.h/2+8+(usableH-gh)/2};this.org.push(o);
   const row=[],mk=[],tex=Gfx.pill(cs-4,cs-4,'rgba(255,255,255,1)',null,Math.min(10,cs*.22));
   for(let i=0;i<N;i++){const c=i%this.cols,r=Math.floor(i/this.cols);const t=new Sprite(tex,cs-4,cs-4);t.x=o.x+(c+.5)*cs;t.y=o.y+(r+.5)*cs;t.color='rgb(64,64,64)';t.cbf=1;t.alpha=.55;t.z=5;s.field.add(t);row.push(t);
    const m=label('✕',cs*.5,white(1,.9));m.x=t.x;m.y=t.y;m.z=6;m.hidden=true;s.field.add(m);mk.push(m)}
   this.tiles.push(row);this.marks.push(mk);
   if(!s.isCPU){const h=label('FELDER ANTIPPEN!',Math.min(18,s.w*.08),s.color);h.x=0;h.y=0;h.z=50;s.node.add(h);h.run(A.sequence([A.wait(4.5),A.fadeOut(.4),A.remove()]))}}}
 cellAt(s,p){const cs=this.cs[s.index],o=this.org[s.index],c=Math.floor((p.x-o.x)/cs),r=Math.floor((p.y-o.y)/cs);if(c<0||c>=this.cols||r<0||r>=this.rows)return null;return r*this.cols+c}
 began(seat,at){const i=this.cellAt(seat,at);if(i!=null)this.act(seat,i)}
 moved(seat,at){const i=this.cellAt(seat,at);if(i!=null&&this.owner[i]===-1)this.act(seat,i)}
 act(s,i){const o=this.owner[i];
  if(o===s.index){if(this.cracked[i]){this.cracked[i]=false;Sfx.play('pop');this.refresh(i)}return}
  if(o===-1){this.owner[i]=s.index;this.cracked[i]=false;Sfx.play('tap');if(!s.isCPU)Haptic.tap()}
  else if(!this.cracked[i]){this.cracked[i]=true;Sfx.play('hit')}
  else{this.owner[i]=s.index;this.cracked[i]=false;Sfx.play('pop');if(!s.isCPU)Haptic.tap('medium');this.addStat('hits',1,s)}
  this.refresh(i);this.recount()}
 refresh(i){const o=this.owner[i];for(const s of this.seats){const t=this.tiles[s.index][i];t.removeAction('pop');
   if(o>=0){t.color=this.seats[o].color;t.alpha=1}else{t.color='rgb(64,64,64)';t.alpha=.55}
   t.setScale(.7);t.run(A.scaleTo(1,.12),'pop');this.marks[s.index][i].hidden=!this.cracked[i]}}
 recount(){const c=Array(this.n).fill(0);for(const o of this.owner)if(o>=0)c[o]++;for(const s of this.seats)if(s.score!==c[s.index])this.setScore(s,c[s.index])}
 gameUpdate(dt){for(const s of this.seats){if(!s.isCPU)continue;this.cpuT[s.index]-=dt;if(this.cpuT[s.index]>0)continue;
  this.cpuT[s.index]=(.55-.35*s.skill)*(.7+Math.random()*.6);const idx=this.owner.map((_,i)=>i);
  let c=idx.filter(i=>this.owner[i]===s.index&&this.cracked[i]);
  if(!c.length||Math.random()>s.skill)c=idx.filter(i=>this.owner[i]===-1);
  if(!c.length)c=idx.filter(i=>this.owner[i]>=0&&this.owner[i]!==s.index&&this.cracked[i]);
  if(!c.length)c=idx.filter(i=>this.owner[i]>=0&&this.owner[i]!==s.index);
  if(c.length)this.act(s,rnd(c))}}
}
Arcade.register('territory',TerritoryGame);
})();
